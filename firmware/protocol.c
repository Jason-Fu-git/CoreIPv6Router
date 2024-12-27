// RIPng protocol implementation
#include "stdio.h"
#include "stdint.h"
#include "packet.h"
#include "dma.h"
#include "timer.h"
#include "protocol.h"
#include "memory.c"

/**
 * @brief Update one memory_rte's validation by checking its timers.
 * @param memory_rte The address of the rte.
 * @return 0 if the rte is NULL, 1 otherwise.
 * @author Eason Liu
 */
int update_memory_rte(struct memory_rte *memory_rte){
    if(memory_rte->lower_timer == 0) return 0;
    if(memory_rte->metric != 16){
        if(check_timeout(TIMEOUT_TIME_LIMIT, memory_rte->lower_timer)){
            // Start GC Timer
            memory_rte->metric = 16;
            memory_rte->lower_timer = (volatile uint8_t *)MTIME_LADDR;
        }
        return 1;
    }
    else{
        if(check_timeout(GARBAGE_COLLECTION_TIME_LIMIT, memory_rte->lower_timer)){
            // Delete the route
            memory_rte->metric = 16;
            memory_rte->lower_timer = 0;
            memory_rte->nexthop_port = 0;
        }
        return 0;
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
            printf("RQ ");
            /*
              - 如果请求只有一个RTE，`destination prefix`为0，`prefix length`为0，`metric`为16，则**发送自己的全部路由表**。
              - 否则，逐一处理RTE，如果自己通往某一network有路由，则将`metric`填为自己的`metric`；若没有路由，填为16。
             */
            if (entry_length == 20 && entries[i].metric == 16 && entries[i].prefix_len == 0){
                // Send all routes
                printf("SARU\n");
                send_triggered_update(&(ip6->dst_addr), &(ip6->src_addr), NULL, 0, 0);
                break;
            }
            else {
                printf("SPRU\n");
                // Send needed routes
                int j = 0;
                for(j = 0; j < NUM_MEMORY_RTE; j++){
                    if(memory_rte[j].ip6_addr.s6_addr32[0] == entries[i].ip6_addr.s6_addr32[0]
                    && memory_rte[j].ip6_addr.s6_addr32[1] == entries[i].ip6_addr.s6_addr32[1]
                    && memory_rte[j].ip6_addr.s6_addr32[2] == entries[i].ip6_addr.s6_addr32[2]
                    && memory_rte[j].ip6_addr.s6_addr32[3] == entries[i].ip6_addr.s6_addr32[3]
                    ){
                        // Route found
                        for(int p = 0; p < PORT_NUM; p++){
                            send_entries[p][send_entry_num] = entries[i];
                            if(update_memory_rte(memory_rte + j) && p != port){
                                send_entries[p][send_entry_num].metric = memory_rte[j].metric;
                            }
                            else{
                                send_entries[p][send_entry_num].metric = 16;
                            }
                        }
                        send_entry_num++;
                        if(send_entry_num == RIPNG_MAX_RTE_NUM){
                            for(int p = 0; p < PORT_NUM; p++){
                                send_triggered_update(&(ip6->dst_addr), &(ip6->src_addr), send_entries[p], RIPNG_MAX_RTE_NUM, p);
                            }
                            send_entry_num = 0;
                        }
                    }
                }
                if(j == NUM_MEMORY_RTE){
                    // Route not found
                    for(int p = 0; p < PORT_NUM; p++){
                        send_entries[p][send_entry_num] = entries[i];
                        send_entries[p][send_entry_num].metric = 16;
                    }
                    send_entry_num++;
                    if(send_entry_num == RIPNG_MAX_RTE_NUM){
                        for(int p = 0; p < PORT_NUM; p++){
                            send_triggered_update(&(ip6->dst_addr), &(ip6->src_addr), send_entries[p], RIPNG_MAX_RTE_NUM, p);
                        }
                        send_entry_num = 0;
                    }
                }
            }
        }
        else // Received RESPONSE
        {
            printf("RR\n");
            // Update memory rte
            int j = 0;
            for(j = 0; j < NUM_MEMORY_RTE; j++){
                if(memory_rte[j].ip6_addr.s6_addr32[0] == entries[i].ip6_addr.s6_addr32[0]
                && memory_rte[j].ip6_addr.s6_addr32[1] == entries[i].ip6_addr.s6_addr32[1]
                && memory_rte[j].ip6_addr.s6_addr32[2] == entries[i].ip6_addr.s6_addr32[2]
                && memory_rte[j].ip6_addr.s6_addr32[3] == entries[i].ip6_addr.s6_addr32[3]
                ){
                    // Route found
                    int new_metric = entries[i].metric + 1;
                    if(new_metric > 16) new_metric = 16;
                    if(new_metric == 16){
                        if(port == memory_rte[j].nexthop_port & 0x1F){ // next_hop same
                            // Delete the route
                            memory_rte[j].metric = 16;
                            memory_rte[j].lower_timer = (volatile uint8_t *)MTIME_LADDR;
                            memory_rte[j].nexthop_port = 0;
                            for(int p = 0; p < PORT_NUM; p++){
                                send_entries[p][send_entry_num] = entries[i];
                                send_entries[p][send_entry_num].metric = 16;
                            }
                            send_entry_num++;
                            if(send_entry_num == RIPNG_MAX_RTE_NUM){
                                printf("STRU\n");
                                struct ip6_addr dst_addr = MULTICAST_ADDR;
                                for(int p = 0; p < PORT_NUM; p++){
                                    send_triggered_update(&(ip6->dst_addr), &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p);
                                }
                                send_entry_num = 0;
                            }
                        }
                        else; // Do nothing
                    }
                    else if(new_metric > memory_rte[j].metric){
                        if(port == memory_rte[j].nexthop_port & 0x1F){ // next_hop same
                            // Update the route
                            memory_rte[j].metric = new_metric;
                            memory_rte[j].lower_timer = (volatile uint8_t *)MTIME_LADDR;
                            memory_rte[j].metric = new_metric;
                            for(int p = 0; p < PORT_NUM; p++){
                                send_entries[p][send_entry_num] = entries[i];
                                send_entries[p][send_entry_num].metric = (p == port) ? 16 : new_metric;
                            }
                            send_entry_num++;
                            if(send_entry_num == RIPNG_MAX_RTE_NUM){
                                printf("STRU\n");
                                struct ip6_addr dst_addr = MULTICAST_ADDR;
                                for(int p = 0; p < PORT_NUM; p++){
                                    send_triggered_update(&(ip6->dst_addr), &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p);
                                }
                                send_entry_num = 0;
                            }
                        }
                        else; // Do nothing
                    }
                    else if(new_metric == memory_rte[j].metric){
                        if(port != memory_rte[j].nexthop_port & 0x1F 
                        && check_timeout(TIMEOUT_TIME_LIMIT >> 1, memory_rte[j].lower_timer)
                        ){ // next_hop NOT same and memory_rte timeout soon
                            // Update the route
                            memory_rte[j].nexthop_port = port | 0x80;
                            memory_rte[j].lower_timer = (volatile uint8_t *)MTIME_LADDR;
                            memory_rte[j].metric = new_metric;
                            for(int p = 0; p < PORT_NUM; p++){
                                send_entries[p][send_entry_num] = entries[i];
                                send_entries[p][send_entry_num].metric = (p == port) ? 16 : new_metric;
                            }
                            send_entry_num++;
                            if(send_entry_num == RIPNG_MAX_RTE_NUM){
                                printf("STRU\n");
                                struct ip6_addr dst_addr = MULTICAST_ADDR;
                                for(int p = 0; p < PORT_NUM; p++){
                                    send_triggered_update(&(ip6->dst_addr), &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p);
                                }
                                send_entry_num = 0;
                            }
                        }
                        else; // Do nothing
                    }
                    else{
                        // Update the route
                        memory_rte[j].nexthop_port = port | 0x80;
                        memory_rte[j].lower_timer = (volatile uint8_t *)MTIME_LADDR;
                        memory_rte[j].metric = new_metric;
                        for(int p = 0; p < PORT_NUM; p++){
                            send_entries[p][send_entry_num] = entries[i];
                            send_entries[p][send_entry_num].metric = (p == port) ? 16 : new_metric;
                        }
                        send_entry_num++;
                        if(send_entry_num == RIPNG_MAX_RTE_NUM){
                            printf("STRU\n");
                            struct ip6_addr dst_addr = MULTICAST_ADDR;
                            for(int p = 0; p < PORT_NUM; p++){
                                send_triggered_update(&(ip6->dst_addr), &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p);
                            }
                            send_entry_num = 0;
                        }
                    }
                    break;
                }
            }
            if(j == NUM_MEMORY_RTE){
                // Add new route
                for(j = 0; j < NUM_MEMORY_RTE; j++){
                    if(memory_rte[j].lower_timer == 0 && entries[i].metric < 15){
                        memory_rte[j].ip6_addr = entries[i].ip6_addr;
                        memory_rte[j].metric = entries[i].metric + 1;
                        memory_rte[j].lower_timer = (volatile uint8_t *)MTIME_LADDR;
                        memory_rte[j].prefix_len = entries[i].prefix_len;
                        memory_rte[j].nexthop_port = port | 0x80;
                        for(int p = 0; p < PORT_NUM; p++){
                            send_entries[p][send_entry_num] = entries[i];
                            send_entries[p][send_entry_num].metric = (p == port) ? 16 : entries[i].metric + 1;
                        }
                        send_entry_num++;
                        if(send_entry_num == RIPNG_MAX_RTE_NUM){
                            printf("STRU\n");
                            struct ip6_addr dst_addr = MULTICAST_ADDR;
                            for(int p = 0; p < PORT_NUM; p++){
                                send_triggered_update(&(ip6->dst_addr), &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p);
                            }
                            send_entry_num = 0;
                        }
                    }
                    break;
                }
            }
        }

        // increment the length and index
        len += 20;
        i++;
    }
    if(send_entry_num > 0){
        if(ripng_hdr->cmd == RIPNG_CMD_REQUEST){
            printf("SPRU\n");
            for(int p = 0; p < PORT_NUM; p++){
                send_triggered_update(&(ip6->dst_addr), &(ip6->src_addr), send_entries[p], RIPNG_MAX_RTE_NUM, p);
            }
            send_entry_num = 0;
        }
        else if(ripng_hdr->cmd == RIPNG_CMD_RESPONSE){
            printf("STRU\n");
            struct ip6_addr dst_addr = MULTICAST_ADDR;
            for(int p = 0; p < PORT_NUM; p++){
                send_triggered_update(&(ip6->dst_addr), &dst_addr, send_entries[p], RIPNG_MAX_RTE_NUM, p);
            }
        }
    }

    return SUCCESS;
}

/**
 * @brief Send multicast request.
 * @note This function will only write the packet to the SRAM.
 *  To initiate the DMA transfer, you need to call _grant_dma_access()
 * @author Jason Fu
 */
void send_multicast_request()
{
    printf("SNQM\n");
    // Write to DMA_BLOCK_RADDR
    volatile struct packet_hdr *packet = (volatile struct packet_hdr *)DMA_BLOCK_RADDR;
    // set the ether header
    packet->ether.padding = 0;
    packet->ether.dst_addr.ether_addr16[0] = 0;
    packet->ether.dst_addr.ether_addr16[1] = 0;
    packet->ether.dst_addr.ether_addr16[2] = 0;
    packet->ether.src_addr.ether_addr16[0] = 0;
    packet->ether.src_addr.ether_addr16[1] = 0;
    packet->ether.src_addr.ether_addr16[2] = 0;
    packet->ether.ethertype = 0xdd86;
    // set the ip6 header
    packet->ip6.version = 0x60;
    packet->ip6.traffic_class = 0;
    packet->ip6.flow_label = 0;
    packet->ip6.payload_len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN + RTE_LEN);
    packet->ip6.next_header = IPPROTO_UDP;
    packet->ip6.hop_limit = 255;
    packet->ip6.src_addr.s6_addr32[0] = 0;
    packet->ip6.src_addr.s6_addr32[1] = 0;
    packet->ip6.src_addr.s6_addr32[2] = 0;
    packet->ip6.src_addr.s6_addr32[3] = 0;
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
 * @param src_addr The source address of the packet.
 * @param dst_addr The destination address of the packet.
 * @param entries The routing table entries.
 * @param num_entries The number of routing table entries. It shouldn't be bigger than RIPNG_MAX_RTE_NUM.
 * @return The size of the packet.
 * @author Eason Liu
 */
int assemble(struct ip6_addr *src_addr, struct ip6_addr *dst_addr, struct ripng_rte *entries, int num_entries){
    struct packet_hdr *packet_hdr = (volatile struct packet_hdr*)DMA_BLOCK_RADDR;
    // set the ether header
    packet_hdr->ether.padding = 0;
    packet_hdr->ether.ethertype = 0x86dd;
    for(int i = 0; i < 3; i++){
        packet_hdr->ether.src_addr.ether_addr16[i] = 0;
        packet_hdr->ether.dst_addr.ether_addr16[i] = 0;
    }
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
    struct ripng_rte *rte = (struct ripng_rte *)packet_hdr + PACKET_HDR_LEN;
    int entries_size = 0;
    for(int i = 0; i < num_entries; i++){
        rte->ip6_addr.s6_addr32[0] = entries[i].ip6_addr.s6_addr32[0];
        rte->ip6_addr.s6_addr32[1] = entries[i].ip6_addr.s6_addr32[1];
        rte->ip6_addr.s6_addr32[2] = entries[i].ip6_addr.s6_addr32[2];
        rte->ip6_addr.s6_addr32[3] = entries[i].ip6_addr.s6_addr32[3];
        rte->prefix_len = entries[i].prefix_len;
        rte->metric = entries[i].metric;
        rte->route_tag = htons(entries[i].route_tag);
        entries_size += RTE_LEN;
    }
    // set the lengths
    packet_hdr->ip6.payload_len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN + entries_size);
    packet_hdr->udp.len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN + entries_size);
    // return the size
    return PACKET_HDR_LEN + entries_size;
}

/**
 * @brief Send triggered update.
 * @note  This function will block until the whole routing table is sent.
 * @param src_addr The source address of the packet.
 * @param dst_addr The destination address of the packet.
 * @param entries The routing table entries.
 * @param num_entries The number of routing table entries. If num_entries > RIPNG_MAX_RTE_NUM, split the entries into multiple packets.
 * @param port The port to send the packet to.
 * @author Eason Liu
 */
void send_triggered_update(struct ip6_addr *src_addr, struct ip6_addr *dst_addr, struct ripng_rte *entries, int num_entries, uint8_t port){
    // TODO: PORT
    if (entries == NULL){
        int send_entry_num = 0;
        struct ripng_rte send_entries[PORT_NUM][RIPNG_MAX_RTE_NUM];
        for(int i = 0; i < NUM_MEMORY_RTE; i++){
            if(update_memory_rte(memory_rte + i)){
                for(int p = 0; p < PORT_NUM; p++){
                    send_entries[p][send_entry_num].ip6_addr = memory_rte[i].ip6_addr;
                    send_entries[p][send_entry_num].prefix_len = memory_rte[i].prefix_len;
                    send_entries[p][send_entry_num].metric = (p == port) ? 16 : memory_rte[i].metric;
                    send_entries[p][send_entry_num].route_tag = 0;
                }
                send_entry_num++;
                if(send_entry_num == RIPNG_MAX_RTE_NUM){
                    int size = assemble(src_addr, dst_addr, send_entries, send_entry_num);
                    _wait_for_dma();
                    *(volatile uint8_t*)DMA_OUT_PORT_ID = port;
                    _grant_dma_access(DMA_BLOCK_RADDR, size, 0);
                    send_entry_num = 0;
                }
            }
        }
    }
    else{
        int start_entrie = 0;
        while((num_entries - start_entrie) > RIPNG_MAX_RTE_NUM){
            int size = assemble(src_addr, dst_addr, &entries[start_entrie], RIPNG_MAX_RTE_NUM);
            _wait_for_dma();
            *(volatile uint8_t*)DMA_OUT_PORT_ID = port;
            _grant_dma_access(DMA_BLOCK_RADDR, size, 0);
            start_entrie += RIPNG_MAX_RTE_NUM;
        }
        int size = assemble(src_addr, dst_addr, &entries[start_entrie], num_entries - start_entrie);
        _wait_for_dma();
        *(volatile uint8_t*)DMA_OUT_PORT_ID = port;
        _grant_dma_access(DMA_BLOCK_RADDR, size, 0);
    }
}

/**
 * @brief Send unsolicited response.
 * @note This function will block until the whole routing table is sent.
 * @author Jason Fu
 */
void send_unsolicited_response()
{
    struct ip6_addr src_addr = {0};
    struct ip6_addr dst_addr = {
        .s6_addr32 = MULTICAST_ADDR};
    printf("STRM\n");
    send_triggered_update(&src_addr, &dst_addr, NULL, 0, 0);
}