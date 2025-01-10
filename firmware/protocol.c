// RIPng protocol implementation
#include "stdio.h"
#include "stdint.h"
#include "packet.h"
#include "dma.h"
#include "timer.h"
#include "protocol.h"
#include "memory.h"

extern struct ip6_addr ip_addrs[PORT_NUM];
extern struct ether_addr mac_addrs[PORT_NUM];

extern int rte_map[NUM_TRIE_NODE];
extern struct memory_rte memory_rte[NUM_MEMORY_RTE];
extern int spare_nexthop_index;
extern int spare_memory_index;
// extern uint32_t last_triggered_time;

extern int TrieInsert(void* prefix, unsigned int length, uint32_t next_hop);
extern int TrieDelete(void* prefix, unsigned int length);
extern int TrieLookup(void* prefix, unsigned int length);
extern void TrieModify(void* prefix, unsigned int length, uint32_t next_hop);

#define ISVALID(rte) (((rte)->nexthop_port & 0x80) != 0)
#define ISINVALID(rte) (((rte)->nexthop_port & 0x80) == 0)
#define ISDIRECT(rte) (((rte)->nexthop_port & 0x40) != 0)
#define PORT_ID(rte) ((rte)->nexthop_port & 0x03)

/**
 * @brief Put a direct route into the routing table.
 * @param ip6_addr The IP address of the direct route.
 * @param prefix_len The prefix length of the direct route.
 * @param port The port ID of the direct route.
 * @author Eason Liu
 */
void config_direct_route(struct ip6_addr *ip6_addr, uint8_t prefix_len, uint8_t port){
    int j;
    for(j = 0; j < NEXTHOP_TABLE_INDEX_NUM; j++){
        struct ip6_addr nexthop_ip6_addr = read_nexthop_table_ip6_addr(NEXTHOP_TABLE_ADDR(j));
        if(read_nexthop_table_port_id(NEXTHOP_TABLE_PORT_ID_ADDR(j)) == port
        && nexthop_ip6_addr.s6_addr32[0] == ip6_addr->s6_addr32[0]
        && nexthop_ip6_addr.s6_addr32[1] == ip6_addr->s6_addr32[1]
        && nexthop_ip6_addr.s6_addr32[2] == ip6_addr->s6_addr32[2]
        && nexthop_ip6_addr.s6_addr32[3] == ip6_addr->s6_addr32[3]
        ){
            break;
        }
    }
    if(j == NEXTHOP_TABLE_INDEX_NUM){
        j = spare_nexthop_index;
        write_nexthop_table_ip6_addr(ip6_addr, NEXTHOP_TABLE_ADDR(j));
        write_nexthop_table_port_id(port, NEXTHOP_TABLE_PORT_ID_ADDR(j));
        spare_nexthop_index++;
        if(spare_nexthop_index == NEXTHOP_TABLE_INDEX_NUM) spare_nexthop_index = 0;
    }
    int trie_index = TrieLookup(ip6_addr, prefix_len);
    if(trie_index >= 0){
        return;
    }
    trie_index = TrieInsert(ip6_addr, prefix_len, j);
    if(trie_index < 0){
        // printf("[TI]%d", trie_index);
        return;
    }
    rte_map[trie_index] = spare_memory_index;
    memory_rte[spare_memory_index].ip6_addr = *ip6_addr;
    memory_rte[spare_memory_index].metric = 1;
    memory_rte[spare_memory_index].lower_timer = (*((volatile uint32_t *)MTIME_LADDR)) & 0xFF;
    memory_rte[spare_memory_index].prefix_len = prefix_len;
    memory_rte[spare_memory_index].nexthop_port = port | 0xc0;
    while(ISVALID(memory_rte + spare_memory_index)){
        spare_memory_index++;
        if(spare_memory_index == NUM_MEMORY_RTE) spare_memory_index = 1;
    }
}

/**
 * @brief Update one memory_rte's validation by checking its timers.
 * @param memory_rte_v The address of the rte.
 * @return 0 if the rte is NULL, 1 otherwise.
 * @author Eason Liu
 */
int update_memory_rte(void *memory_rte_v){
    struct memory_rte* memory_rte = (struct memory_rte*) memory_rte_v;
    if(ISINVALID(memory_rte)){
        return 0;
    }
    if(ISDIRECT(memory_rte)){
        return 1;
    }
    if(memory_rte->metric != 16){
        if(check_timeout(TIMEOUT_TIME_LIMIT, memory_rte->lower_timer)){
            // Start GC Timer
            memory_rte->metric = 16;
            memory_rte->lower_timer = *((volatile uint32_t *)MTIME_LADDR);
        }
        return 1;
    }
    else{
        if(check_timeout(GARBAGE_COLLECTION_TIME_LIMIT, memory_rte->lower_timer)){
            // Delete the route
            // delete memory_rte
            // trie.delete(addr, prefix_length), return index
            // invalidate (trie->memory[index])
            int trie_index = TrieDelete(&(memory_rte->ip6_addr), memory_rte->prefix_len);
            if(trie_index < 0){
                printf("[TD]%d", trie_index);
                memory_rte->lower_timer = 0;
                memory_rte->nexthop_port = 0;
                return 0;
            }
            rte_map[trie_index] = 0;
            memory_rte->lower_timer = 0;
            memory_rte->nexthop_port = 0;
            return 0;
        }
        return 1;
    }
}

/**
 * @brief Disassemble the packet and check the correctness of the packet.
 * @param base_addr The base address of the packet.
 * @param length The length of the packet.
 * @param port The port the packet is sent from.
 * @return RipngErrorCode The error code of the packet.
 * @authors Jason Fu, Eason Liu
 */
RipngErrorCode disassemble(uint32_t base_addr, uint32_t length, uint8_t port)
{
    base_addr = base_addr + PADDING + ETHER_HDR_LEN;
    // 读取IPv6头部
    struct ip6_hdr *ip6 = (struct ip6_hdr *)base_addr;
    // 2. IPv6 Header 中的 Payload Length 加上 Header 长度是否等于 len。
    int payload_len = ntohs(ip6->payload_len);
    if (PADDING + ETHER_HDR_LEN + IP6_HDR_LEN + payload_len != length)
    {
        return ERR_LENGTH;
    }
    // 3. IPv6 Header 中的 Next header 字段是否为 UDP 协议。
    if (ip6->next_header != IPPROTO_UDP)
    {
        return ERR_IPV6_NEXT_HEADER_NOT_UDP;
    }
    // 4. IPv6 Header 中的 Payload Length 是否包括一个 UDP header 的长度。
    if (payload_len < 8)
    {
        return ERR_LENGTH;
    }
    // get upd header
    struct udp_hdr *udp = (struct udp_hdr *)(base_addr + IP6_HDR_LEN);
    // 5. 检查 UDP 源端口和目的端口是否都为 521。
    if (ntohs(udp->src_port) != UDP_PORT_RIPNG || ntohs(udp->dst_port) != UDP_PORT_RIPNG)
    {
        return ERR_UDP_PORT_NOT_RIPNG;
    }
    /*
     * 6. 检查 UDP header 中 Length 是否等于 UDP header 长度加上 RIPng header
     * 长度加上 RIPng entry 长度的整数倍。
     */
    int udp_len = ntohs(udp->len);
    // get RIPng header
    struct ripng_hdr *ripng_hdr = (struct ripng_hdr *)(base_addr + IP6_HDR_LEN + UDP_HDR_LEN);
    /*
     * 7. 检查 RIPng header 中的 Command 是否为 1 或 2，
     * Version 是否为 1，Zero（Reserved） 是否为 0。
     */
    if (ripng_hdr->cmd != 1 && ripng_hdr->cmd != 2)
    {
        return ERR_RIPNG_BAD_COMMAND;
    }
    if (ripng_hdr->vers != 1)
    {
        return ERR_RIPNG_BAD_VERSION;
    }
    if (ripng_hdr->reserved != 0)
    {
        return ERR_RIPNG_BAD_ZERO;
    }
    // get the entries
    struct ripng_rte *entries = (struct ripng_rte *)(base_addr + IP6_HDR_LEN + UDP_HDR_LEN + RIPNG_HDR_LEN);
    int entry_length = udp_len - UDP_HDR_LEN - RIPNG_HDR_LEN;
    int len = 0, i = 0;
    int send_entry_num = 0;
    struct ripng_rte send_entries[PORT_NUM][RIPNG_MAX_RTE_NUM];
    while (len < entry_length)
    {
        /*
         * 8. 对每个 RIPng entry，当 Metric=0xFF 时，检查 Prefix Len
         * 和 Route Tag 是否为 0。
         */
        if (entries[i].metric == 0xff)
        {
            if (entries[i].prefix_len != 0)
            {
                return ERR_RIPNG_BAD_PREFIX_LEN;
            }
            if (entries[i].route_tag != 0)
            {
                return ERR_RIPNG_BAD_ROUTE_TAG;
            }
        }
        else
        {
            /*
             * 9. 对每个 RIPng entry，当 Metric!=0xFF 时，检查 Metric 是否属于
             * [1,16]，并检查 Prefix Len 是否属于 [0,128]，Prefix Len 是否与 IPv6 prefix
             * 字段组成合法的 IPv6 前缀。
             */
            if (entries[i].metric < 1 || entries[i].metric > 16)
            {
                return ERR_RIPNG_BAD_METRIC;
            }
            if (entries[i].prefix_len < 0 || entries[i].prefix_len > 128)
            {
                return ERR_RIPNG_BAD_PREFIX_LEN;
            }
            // check whether the prefix is valid
            int prefix_len = entries[i].prefix_len;
            for (int j = 0; j < 16; j++)
            {
                if (prefix_len >= 8)
                {
                    prefix_len -= 8;
                }
                else if (prefix_len > 0)
                {
                    uint8_t mask = 0xff >> prefix_len;
                    if ((entries[i].ip6_addr.s6_addr8[j] & mask) != 0)
                    {
                        return ERR_RIPNG_INCONSISTENT_PREFIX_LENGTH;
                    }
                    prefix_len = 0;
                }
                else
                {
                    if (entries[i].ip6_addr.s6_addr8[j] != 0)
                    {
                        return ERR_RIPNG_INCONSISTENT_PREFIX_LENGTH;
                    }
                }
            }
        }

        if (ripng_hdr->cmd == RIPNG_CMD_REQUEST) // Received REQUEST
        {
            /*
              - 如果请求只有一个RTE，`destination prefix`为0，`prefix length`为0，`metric`为16，则**发送自己的全部路由表**。
              - 否则，逐一处理RTE，如果自己通往某一network有路由，则将`metric`填为自己的`metric`；若没有路由，填为16。
             */
            // lookup trie (addr, prefix_length), return index1
            // (trie->memory[index1]->index2
            // memory_rte[index2]->metric
            int j;
            for(j = 0; j < NEXTHOP_TABLE_INDEX_NUM; j++){
                struct ip6_addr nexthop_ip6_addr = read_nexthop_table_ip6_addr(NEXTHOP_TABLE_ADDR(j));
                if(read_nexthop_table_port_id(NEXTHOP_TABLE_PORT_ID_ADDR(j)) == port
                && nexthop_ip6_addr.s6_addr32[0] == ip6->src_addr.s6_addr32[0]
                && nexthop_ip6_addr.s6_addr32[1] == ip6->src_addr.s6_addr32[1]
                && nexthop_ip6_addr.s6_addr32[2] == ip6->src_addr.s6_addr32[2]
                && nexthop_ip6_addr.s6_addr32[3] == ip6->src_addr.s6_addr32[3]
                ){
                    break;
                }
            }
            if(j == NEXTHOP_TABLE_INDEX_NUM){
                j = spare_nexthop_index;
                write_nexthop_table_ip6_addr(&(ip6->src_addr), NEXTHOP_TABLE_ADDR(j));
                write_nexthop_table_port_id(port, NEXTHOP_TABLE_PORT_ID_ADDR(j));
                spare_nexthop_index++;
                if(spare_nexthop_index == NEXTHOP_TABLE_INDEX_NUM) spare_nexthop_index = 0;
            }
            if (entry_length == 20 && entries[i].metric == 16 && entries[i].prefix_len == 0
            && entries[i].ip6_addr.s6_addr32[0] == 0 && entries[i].ip6_addr.s6_addr32[1] == 0
            && entries[i].ip6_addr.s6_addr32[2] == 0 && entries[i].ip6_addr.s6_addr32[3] == 0
            ){
                // Send all routes
                send_response(&(ip6->dst_addr), &(ip6->src_addr), NULL, 0, port, 0);
                break;
            }
            else {
                // Send needed routes
                int trie_index = TrieLookup(&(entries[i].ip6_addr), entries[i].prefix_len);
                if(trie_index >= 0){
                    int mem_id = rte_map[trie_index];
                    // Route found
                    send_entries[port][send_entry_num] = entries[i];
                    if(update_memory_rte(memory_rte + mem_id) && (PORT_ID(memory_rte + mem_id)) != port){
                        send_entries[port][send_entry_num].metric = memory_rte[mem_id].metric;
                    }
                    else{
                        send_entries[port][send_entry_num].metric = 16;
                    }
                    send_entry_num++;
                    if(send_entry_num == RIPNG_MAX_RTE_NUM){
                        send_response(&(ip6->dst_addr), &(ip6->src_addr), send_entries[port], RIPNG_MAX_RTE_NUM, port, 0);
                        send_entry_num = 0;
                    }
                }
                else{
                    // Route not found
                    send_entries[port][send_entry_num] = entries[i];
                    send_entries[port][send_entry_num].metric = 16;
                    send_entry_num++;
                    if(send_entry_num == RIPNG_MAX_RTE_NUM){
                        send_response(&(ip6->dst_addr), &(ip6->src_addr), send_entries[port], RIPNG_MAX_RTE_NUM, port, 0);
                        send_entry_num = 0;
                    }
                }
            }
        }
        else // Received RESPONSE
        {
            // Update memory rte
            // Check nexthop_table (src_addr, port), return index (insert:FIFO)
            // Lookup if the rte exists
            // If not, insert trie (addr, prefix_length, index), return (trie->memory) index1
            // memory: find a space, return index2
            // (trie->memory)[index1]: insert index2
            int j;
            for(j = 0; j < NEXTHOP_TABLE_INDEX_NUM; j++){
                struct ip6_addr nexthop_ip6_addr = read_nexthop_table_ip6_addr(NEXTHOP_TABLE_ADDR(j));
                if(read_nexthop_table_port_id(NEXTHOP_TABLE_PORT_ID_ADDR(j)) == port
                && nexthop_ip6_addr.s6_addr32[0] == ip6->src_addr.s6_addr32[0]
                && nexthop_ip6_addr.s6_addr32[1] == ip6->src_addr.s6_addr32[1]
                && nexthop_ip6_addr.s6_addr32[2] == ip6->src_addr.s6_addr32[2]
                && nexthop_ip6_addr.s6_addr32[3] == ip6->src_addr.s6_addr32[3]
                ){
                    break;
                }
            }
            if(j == NEXTHOP_TABLE_INDEX_NUM){
                j = spare_nexthop_index;
                write_nexthop_table_ip6_addr(&(ip6->src_addr), NEXTHOP_TABLE_ADDR(j));
                write_nexthop_table_port_id(port, NEXTHOP_TABLE_PORT_ID_ADDR(j));
                spare_nexthop_index++;
                if(spare_nexthop_index == NEXTHOP_TABLE_INDEX_NUM) spare_nexthop_index = 0;
            }
            int trie_index = TrieLookup(&(entries[i].ip6_addr), entries[i].prefix_len);
            if(trie_index > 0){
                int mem_id = rte_map[trie_index];
                // Route found
                int new_metric = entries[i].metric + 1;
                if(new_metric > 16) new_metric = 16;
                if(new_metric == 16){
                    if(port == (PORT_ID(memory_rte + mem_id))){ // next_hop same
                        // Delete the route
                        int trie_index = TrieLookup(&(memory_rte[mem_id].ip6_addr), memory_rte[mem_id].prefix_len);
                        if(trie_index < 0){
                            printf("[TF]%d", trie_index);
                            memory_rte[mem_id].metric = 16;
                            memory_rte[mem_id].lower_timer = 0;
                            memory_rte[mem_id].nexthop_port = 0;
                            return ERR_TRIE;
                        }
                        memory_rte[mem_id].metric = 16;
                        memory_rte[mem_id].lower_timer = (*((volatile uint32_t *)MTIME_LADDR)) & 0xFF;
                        // if(check_timeout(TRIGGERED_RESPONSE_TIME_INTERVAL, last_triggered_time)){
                        //     last_triggered_time = *((volatile uint32_t *)MTIME_LADDR);
                        // }
                        // else{
                        //     continue;
                        // }
                        for(int p = 0; p < PORT_NUM; p++){
                            send_entries[p][send_entry_num] = entries[i];
                            send_entries[p][send_entry_num].metric = 16;
                        }
                        send_entry_num++;
                        if(send_entry_num == RIPNG_MAX_RTE_NUM){
                            struct ip6_addr dst_addr = {.s6_addr32 = MULTICAST_ADDR};
                            for(int p = 0; p < PORT_NUM; p++){
                                send_response(ip_addrs + p, &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p, 1);
                            }
                            send_entry_num = 0;
                        }
                    }
                    else; // Do nothing
                }
                else if(new_metric > memory_rte[mem_id].metric){
                    if(port == (PORT_ID(memory_rte + mem_id))){ // next_hop same
                        // Update the route
                        memory_rte[mem_id].metric = new_metric;
                        memory_rte[mem_id].lower_timer = (*((volatile uint32_t *)MTIME_LADDR)) & 0xFF;
                        // if(check_timeout(TRIGGERED_RESPONSE_TIME_INTERVAL, last_triggered_time)){
                        //     last_triggered_time = *((volatile uint32_t *)MTIME_LADDR);
                        // }
                        // else{
                        //     continue;
                        // }
                        for(int p = 0; p < PORT_NUM; p++){
                            send_entries[p][send_entry_num] = entries[i];
                            send_entries[p][send_entry_num].metric = (p == port) ? 16 : new_metric;
                        }
                        send_entry_num++;
                        if(send_entry_num == RIPNG_MAX_RTE_NUM){
                            struct ip6_addr dst_addr = {.s6_addr32 = MULTICAST_ADDR};
                            for(int p = 0; p < PORT_NUM; p++){
                                send_response(ip_addrs + p, &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p, 1);
                            }
                            send_entry_num = 0;
                        }
                    }
                    else; // Do nothing
                }
                else if(new_metric == memory_rte[mem_id].metric){
                    if(port != (PORT_ID(memory_rte + mem_id)) 
                    && check_timeout(TIMEOUT_TIME_LIMIT >> 1, memory_rte[mem_id].lower_timer)
                    ){ // next_hop NOT same and memory_rte timeout soon
                        // Update the route
                        int nexthop_index = 0;
                        for(nexthop_index = 0; nexthop_index < NEXTHOP_TABLE_INDEX_NUM; nexthop_index++){
                            struct ip6_addr nexthop_ip6_addr = read_nexthop_table_ip6_addr(NEXTHOP_TABLE_ADDR(nexthop_index));
                            if(read_nexthop_table_port_id(NEXTHOP_TABLE_PORT_ID_ADDR(nexthop_index)) == port
                            && nexthop_ip6_addr.s6_addr32[0] == ip6->src_addr.s6_addr32[0]
                            && nexthop_ip6_addr.s6_addr32[1] == ip6->src_addr.s6_addr32[1]
                            && nexthop_ip6_addr.s6_addr32[2] == ip6->src_addr.s6_addr32[2]
                            && nexthop_ip6_addr.s6_addr32[3] == ip6->src_addr.s6_addr32[3]
                            ){
                                break;
                            }
                        }
                        if(nexthop_index == NEXTHOP_TABLE_INDEX_NUM){
                            nexthop_index = spare_nexthop_index;
                            write_nexthop_table_ip6_addr(&(ip6->src_addr), NEXTHOP_TABLE_ADDR(nexthop_index));
                            write_nexthop_table_port_id(port, NEXTHOP_TABLE_PORT_ID_ADDR(nexthop_index));
                            spare_nexthop_index++;
                            if(spare_nexthop_index == NEXTHOP_TABLE_INDEX_NUM) spare_nexthop_index = 0;
                        }
                        TrieModify(&(memory_rte[mem_id].ip6_addr), memory_rte[mem_id].prefix_len, nexthop_index);
                        memory_rte[mem_id].nexthop_port = port | 0x80;
                        memory_rte[mem_id].lower_timer = (*((volatile uint32_t *)MTIME_LADDR)) & 0xFF;
                        // if(check_timeout(TRIGGERED_RESPONSE_TIME_INTERVAL, last_triggered_time)){
                        //     last_triggered_time = *((volatile uint32_t *)MTIME_LADDR);
                        // }
                        // else{
                        //     continue;
                        // }
                        for(int p = 0; p < PORT_NUM; p++){
                            send_entries[p][send_entry_num] = entries[i];
                            send_entries[p][send_entry_num].metric = (p == port) ? 16 : new_metric;
                        }
                        send_entry_num++;
                        if(send_entry_num == RIPNG_MAX_RTE_NUM){
                            struct ip6_addr dst_addr = {.s6_addr32 = MULTICAST_ADDR};
                            for(int p = 0; p < PORT_NUM; p++){
                                send_response(ip_addrs + p, &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p, 1);
                            }
                            send_entry_num = 0;
                        }
                    }
                    else{ // Nexthop and metric both same
                        // Update timer
                        memory_rte[mem_id].lower_timer = (*((volatile uint32_t *)MTIME_LADDR)) & 0xFF;
                    }
                }
                else{
                    // Update the route
                    if(port != (PORT_ID(memory_rte + mem_id))){
                        int nexthop_index = 0;
                        for(nexthop_index = 0; nexthop_index < NEXTHOP_TABLE_INDEX_NUM; nexthop_index++){
                            struct ip6_addr nexthop_ip6_addr = read_nexthop_table_ip6_addr(NEXTHOP_TABLE_ADDR(nexthop_index));
                            if(read_nexthop_table_port_id(NEXTHOP_TABLE_PORT_ID_ADDR(nexthop_index)) == port
                            && nexthop_ip6_addr.s6_addr32[0] == ip6->src_addr.s6_addr32[0]
                            && nexthop_ip6_addr.s6_addr32[1] == ip6->src_addr.s6_addr32[1]
                            && nexthop_ip6_addr.s6_addr32[2] == ip6->src_addr.s6_addr32[2]
                            && nexthop_ip6_addr.s6_addr32[3] == ip6->src_addr.s6_addr32[3]
                            ){
                                break;
                            }
                        }
                        if(nexthop_index == NEXTHOP_TABLE_INDEX_NUM){
                            nexthop_index = spare_nexthop_index;
                            write_nexthop_table_ip6_addr(&(ip6->src_addr), NEXTHOP_TABLE_ADDR(nexthop_index));
                            write_nexthop_table_port_id(port, NEXTHOP_TABLE_PORT_ID_ADDR(nexthop_index));
                            spare_nexthop_index++;
                            if(spare_nexthop_index == NEXTHOP_TABLE_INDEX_NUM) spare_nexthop_index = 0;
                        }
                        TrieModify(&(memory_rte[mem_id].ip6_addr), memory_rte[mem_id].prefix_len, nexthop_index);
                    }
                    memory_rte[mem_id].nexthop_port = port | 0x80;
                    memory_rte[mem_id].lower_timer = (*((volatile uint32_t *)MTIME_LADDR)) & 0xFF;
                    memory_rte[mem_id].metric = new_metric;
                    // if(check_timeout(TRIGGERED_RESPONSE_TIME_INTERVAL, last_triggered_time)){
                    //     last_triggered_time = *((volatile uint32_t *)MTIME_LADDR);
                    // }
                    // else{
                    //     continue;
                    // }
                    for(int p = 0; p < PORT_NUM; p++){
                        send_entries[p][send_entry_num] = entries[i];
                        send_entries[p][send_entry_num].metric = (p == port) ? 16 : new_metric;
                    }
                    send_entry_num++;
                    if(send_entry_num == RIPNG_MAX_RTE_NUM){
                        struct ip6_addr dst_addr = {.s6_addr32 = MULTICAST_ADDR};
                        for(int p = 0; p < PORT_NUM; p++){
                            send_response(ip_addrs + p, &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p, 1);
                        }
                        send_entry_num = 0;
                    }
                }
            }
            else{
                if(entries[i].metric >= 16) { continue; }
                // Add new route
                int trie_index = TrieInsert(&(entries[i].ip6_addr), entries[i].prefix_len, j);
                if(trie_index < 0){
                    printf("[TI]%d", trie_index);
                    return ERR_TRIE;
                }
                rte_map[trie_index] = spare_memory_index;
                memory_rte[spare_memory_index].ip6_addr = entries[i].ip6_addr;
                memory_rte[spare_memory_index].metric = entries[i].metric + 1;
                memory_rte[spare_memory_index].lower_timer = (*((volatile uint32_t *)MTIME_LADDR)) & 0xFF;
                memory_rte[spare_memory_index].prefix_len = entries[i].prefix_len;
                memory_rte[spare_memory_index].nexthop_port = port | 0x80;
                while(ISVALID(memory_rte + spare_memory_index)){
                    spare_memory_index++;
                    if(spare_memory_index == NUM_MEMORY_RTE) spare_memory_index = 1;
                }
                // if(check_timeout(TRIGGERED_RESPONSE_TIME_INTERVAL, last_triggered_time)){
                //     last_triggered_time = *((volatile uint32_t *)MTIME_LADDR);
                // }
                // else{
                //     continue;
                // }
                for(int p = 0; p < PORT_NUM; p++){
                    send_entries[p][send_entry_num] = entries[i];
                    send_entries[p][send_entry_num].metric = (p == port) ? 16 : entries[i].metric + 1;
                }
                send_entry_num++;
                if(send_entry_num == RIPNG_MAX_RTE_NUM){
                    struct ip6_addr dst_addr = {.s6_addr32 = MULTICAST_ADDR};
                    for(int p = 0; p < PORT_NUM; p++){
                        send_response(&(ip6->dst_addr), &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p, 1);
                    }
                    send_entry_num = 0;
                }
            }
        }

        // increment the length and index
        len += 20;
        i++;
    }
    if(send_entry_num > 0){
        if(ripng_hdr->cmd == RIPNG_CMD_REQUEST){
            send_response(&(ip6->dst_addr), &(ip6->src_addr), send_entries[port], send_entry_num, port, 0);
            send_entry_num = 0;
        }
        else if(ripng_hdr->cmd == RIPNG_CMD_RESPONSE){
            // if(check_timeout(TRIGGERED_RESPONSE_TIME_INTERVAL, last_triggered_time)){
            //     last_triggered_time = *((volatile uint32_t *)MTIME_LADDR);
            // }
            // else{
            //     return SUCCESS;
            // }
            struct ip6_addr dst_addr = {.s6_addr32 = MULTICAST_ADDR};
            for(int p = 0; p < PORT_NUM; p++){
                send_response(ip_addrs + p, &dst_addr, send_entries[p], send_entry_num, p, 1);
            }
        }
    }

    return SUCCESS;
}

/**
 * @brief Send multicast request.
 * @note This function will only write the packet to the SRAM.
 *  To initiate the DMA transfer, you need to call _grant_dma_access()
 * @author Jason Fu, Eason Liu
 */
void send_multicast_request(int port)
{
    // Write to DMA_BLOCK_RADDR
    volatile struct packet_hdr *packet = (volatile struct packet_hdr *)DMA_BLOCK_RADDR;
    // set the ether header
    packet->ether.padding = 0;
    packet->ether.dst_addr.ether_addr16[0] = htons(0x3333);
    packet->ether.dst_addr.ether_addr16[1] = 0;
    packet->ether.dst_addr.ether_addr16[2] = htons(0x0009);
    packet->ether.src_addr = mac_addrs[port];
    packet->ether.ethertype = 0xdd86;
    // set the ip6 header
    packet->ip6.version = 0x60;
    packet->ip6.traffic_class = 0;
    packet->ip6.flow_label = 0;
    packet->ip6.payload_len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN + RTE_LEN);
    packet->ip6.next_header = IPPROTO_UDP;
    packet->ip6.hop_limit = 255;
    packet->ip6.src_addr = ip_addrs[port];
    packet->ip6.dst_addr.s6_addr32[0] = htonl(0xff020000);
    packet->ip6.dst_addr.s6_addr32[1] = 0;
    packet->ip6.dst_addr.s6_addr32[2] = 0;
    packet->ip6.dst_addr.s6_addr32[3] = htonl(0x00000009);
    // set the udp header
    packet->udp.src_port = htons(UDP_PORT_RIPNG);
    packet->udp.dst_port = htons(UDP_PORT_RIPNG);
    packet->udp.len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN + RTE_LEN);
    packet->udp.checksum = 0;
    // set the ripng header
    packet->ripng.cmd = RIPNG_CMD_REQUEST;
    packet->ripng.vers = 1;
    packet->ripng.reserved = 0;
    // append an RTE
    struct ripng_rte *rte = (struct ripng_rte *)(DMA_BLOCK_RADDR + PADDING + ETHER_HDR_LEN + IP6_HDR_LEN + UDP_HDR_LEN + RIPNG_HDR_LEN);
    rte->ip6_addr.s6_addr32[0] = 0;
    rte->ip6_addr.s6_addr32[1] = 0;
    rte->ip6_addr.s6_addr32[2] = 0;
    rte->ip6_addr.s6_addr32[3] = 0;
    rte->route_tag = 0;
    rte->prefix_len = 0;
    rte->metric = 16;
    // Set the length to DMA_OUT_LENGTH
    *(volatile uint32_t *)DMA_OUT_LENGTH = PADDING + ETHER_HDR_LEN + IP6_HDR_LEN + UDP_HDR_LEN + RIPNG_HDR_LEN + RTE_LEN;
}

/**
 * @brief Assemble a packet.
 * @param src_addr_v The source address of the packet.
 * @param dst_addr_v The destination address of the packet.
 * @param entries_v The routing table entries.
 * @param num_entries The number of routing table entries. It shouldn't be bigger than RIPNG_MAX_RTE_NUM.
 * @param port The port to send the packet to.
 * @param is_multicast Whether the packet is multicast or unicast.
 * @return The size of the packet.
 * @author Eason Liu
 */
int assemble(void *src_addr_v, void *dst_addr_v, void *entries_v, int num_entries, uint8_t port, uint8_t is_multicast){
    struct ripng_rte *entries = (struct ripng_rte *)entries_v;
    struct ip6_addr *src_addr = (struct ip6_addr *)src_addr_v;
    struct ip6_addr *dst_addr = (struct ip6_addr *)dst_addr_v;
    volatile struct packet_hdr *packet_hdr = (struct packet_hdr*)DMA_BLOCK_RADDR;
    // set the ether header
    packet_hdr->ether.padding = 0;
    packet_hdr->ether.ethertype = 0xdd86;
    if(is_multicast){
        packet_hdr->ether.dst_addr.ether_addr16[0] = htons(0x3333);
        packet_hdr->ether.dst_addr.ether_addr16[1] = 0;
        packet_hdr->ether.dst_addr.ether_addr16[2] = htons(0x0009);
    }
    else{
        for(int i = 0; i < 3; i++){
            packet_hdr->ether.dst_addr.ether_addr16[i] = 0;
        }
    }
    packet_hdr->ether.src_addr = mac_addrs[port];
    // set the ip6 header
    packet_hdr->ip6.version = 0x60;
    packet_hdr->ip6.traffic_class = 0;
    packet_hdr->ip6.flow_label = 0;
    packet_hdr->ip6.next_header = IPPROTO_UDP;
    packet_hdr->ip6.hop_limit = 255;
    for(int i = 0; i < 4; i++){
        packet_hdr->ip6.src_addr.s6_addr32[i] = src_addr->s6_addr32[i];
        packet_hdr->ip6.dst_addr.s6_addr32[i] = dst_addr->s6_addr32[i];
    }
    // set the udp header
    packet_hdr->udp.src_port = packet_hdr->udp.dst_port = htons(UDP_PORT_RIPNG);
    packet_hdr->udp.checksum = 0;
    // set the ripng header
    packet_hdr->ripng.cmd = RIPNG_CMD_RESPONSE;
    packet_hdr->ripng.vers = 1;
    packet_hdr->ripng.reserved = 0;
    // set the routing table entries
    volatile struct ripng_rte *rte = (struct ripng_rte *)(packet_hdr + 1);
    int entries_size = 0;
    for(int i = 0; i < num_entries; i++){
        rte[i].ip6_addr.s6_addr32[0] = entries[i].ip6_addr.s6_addr32[0];
        rte[i].ip6_addr.s6_addr32[1] = entries[i].ip6_addr.s6_addr32[1];
        rte[i].ip6_addr.s6_addr32[2] = entries[i].ip6_addr.s6_addr32[2];
        rte[i].ip6_addr.s6_addr32[3] = entries[i].ip6_addr.s6_addr32[3];
        rte[i].prefix_len = entries[i].prefix_len;
        rte[i].metric = entries[i].metric;
        rte[i].route_tag = htons(entries[i].route_tag);
        entries_size += RTE_LEN;
    }
    // set the lengths
    packet_hdr->ip6.payload_len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN + entries_size);
    packet_hdr->udp.len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN + entries_size);
    // return the size
    return PACKET_HDR_LEN + entries_size;
}

/**
 * @brief Send response.
 * @note  This function will block until the whole routing table is sent.
 *  No multicast logic should be in and after this function.
 * @param src_addr_v The source address of the packet.
 * @param dst_addr_v The destination address of the packet.
 * @param entries_v The routing table entries.
 * @param num_entries The number of routing table entries. If num_entries > RIPNG_MAX_RTE_NUM, split the entries into multiple packets.
 * @param port The port to send the packet to.
 * @param is_multicast Whether the packet is multicast or unicast.
 * @author Eason Liu
 */
void send_response(void *src_addr_v, void *dst_addr_v, void *entries_v, int num_entries, uint8_t port, uint8_t is_multicast){
    struct ripng_rte *entries = (struct ripng_rte *)entries_v;
    struct ip6_addr *src_addr = (struct ip6_addr *)src_addr_v;
    struct ip6_addr *dst_addr = (struct ip6_addr *)dst_addr_v;
    if (entries == NULL){
        int send_entry_num = 0;
        struct ripng_rte send_entries[RIPNG_MAX_RTE_NUM];
        for(int i = 1; i < spare_memory_index; i++){
            if(update_memory_rte(memory_rte + i)){
                send_entries[send_entry_num].ip6_addr = memory_rte[i].ip6_addr;
                send_entries[send_entry_num].prefix_len = memory_rte[i].prefix_len;
                send_entries[send_entry_num].metric = (PORT_ID(memory_rte + i) == port) ? 16 : memory_rte[i].metric;
                send_entries[send_entry_num].route_tag = 0;
                send_entry_num++;
                if(send_entry_num == RIPNG_MAX_RTE_NUM){
                    int size = assemble(ip_addrs + port, dst_addr, send_entries, RIPNG_MAX_RTE_NUM, port, is_multicast);
                    if(_check_dma_busy()) _wait_for_dma();
                    *((volatile uint32_t *)DMA_CPU_STB) = 0;
                    *(volatile uint8_t*)DMA_OUT_PORT_ID = port;
                    _grant_dma_access(DMA_BLOCK_RADDR, size, 0);
                    *(volatile uint32_t *)DMA_OUT_LENGTH = 0;
                    send_entry_num = 0;
                }
            }
        }
        if(send_entry_num > 0){
            int size = assemble(ip_addrs + port, dst_addr, send_entries, send_entry_num, port, is_multicast);
            if(_check_dma_busy()) _wait_for_dma();
            *((volatile uint32_t *)DMA_CPU_STB) = 0;
            *(volatile uint8_t*)DMA_OUT_PORT_ID = port;
            _grant_dma_access(DMA_BLOCK_RADDR, size, 0);
            *(volatile uint32_t *)DMA_OUT_LENGTH = 0;
        }
    }
    else{
        int start_entrie = 0;
        while((num_entries - start_entrie) > RIPNG_MAX_RTE_NUM){
            int size = assemble(src_addr, dst_addr, &entries[start_entrie], RIPNG_MAX_RTE_NUM, port, is_multicast);
            if(_check_dma_busy()) _wait_for_dma();
            *((volatile uint32_t *)DMA_CPU_STB) = 0;
            *(volatile uint8_t*)DMA_OUT_PORT_ID = port;
            _grant_dma_access(DMA_BLOCK_RADDR, size, 0);
            *(volatile uint32_t *)DMA_OUT_LENGTH = 0;
            start_entrie += RIPNG_MAX_RTE_NUM;
        }
        int size = assemble(src_addr, dst_addr, &entries[start_entrie], num_entries - start_entrie, port, is_multicast);
        if(_check_dma_busy()) _wait_for_dma();
        *((volatile uint32_t *)DMA_CPU_STB) = 0;
        *(volatile uint8_t*)DMA_OUT_PORT_ID = port;
        _grant_dma_access(DMA_BLOCK_RADDR, size, 0);
        *(volatile uint32_t *)DMA_OUT_LENGTH = 0;
    }
}

/**
 * @brief Send unsolicited response.
 * @note This function will block until the whole routing table is sent.
 * @author Jason Fu
 */
void send_unsolicited_response()
{
    struct ip6_addr dst_addr = {.s6_addr32 = MULTICAST_ADDR};
    for(int p = 0; p < PORT_NUM; p++){
        send_response(ip_addrs + p, &dst_addr, NULL, 0, p, 1);
    }
}