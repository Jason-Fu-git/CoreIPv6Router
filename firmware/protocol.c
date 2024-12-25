// RIPng protocol implementation
#include "stdio.h"
#include "stdint.h"
#include "packet.h"
#include "dma.h"

/**
 * @brief Disassemble the packet and check the correctness of the packet.
 * @param base_addr The base address of the packet.
 * @param length The length of the packet.
 * @return RipngErrorCode The error code of the packet.
 *
 */
RipngErrorCode disassemble(uint32_t base_addr, uint32_t length)
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

        if (ripng_hdr->cmd == RIPNG_CMD_REQUEST)
        {
            // TODO: Handle the request
            /*
              - 如果请求只有一个RTE，`destination prefix`为0，`prefix length`为0，`metric`为16，则**发送自己的全部路由表**。
              - 否则，逐一处理RTE，如果自己通往某一network有路由，则将`metric`填为自己的`metric`；若没有路由，填为16。
             */
        }
        else
        {
            // TODO: check the route table and trigger the update
        }

        // increment the length and index
        len += 20;
        i++;
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
    // Write to DMA_BLOCK_RADDR
    volatile struct packet_hdr *packet = (volatile struct packet_hdr *)DMA_BLOCK_RADDR;
    // set the ether header
    packet->ether.padding = 0;
    packet->ether.ethertype = 0x86dd;
    // set the ip6 header
    packet->ip6.version = 6;
    packet->ip6.traffic_class = 0;
    packet->ip6.flow_label = 0;
    packet->ip6.payload_len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN);
    packet->ip6.next_header = IPPROTO_UDP;
    packet->ip6.hop_limit = 64;
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
    packet->udp.len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN);
    packet->udp.checksum = 0;
    // set the ripng header
    packet->ripng.cmd = RIPNG_CMD_REQUEST;
    packet->ripng.vers = 1;
    packet->ripng.reserved = 0;
    // Set the length to DMA_OUT_LENGTH
    *(volatile uint32_t *)DMA_OUT_LENGTH = PADDING + ETHER_HDR_LEN + IP6_HDR_LEN + UDP_HDR_LEN + RIPNG_HDR_LEN;
}

/**
 * @brief Assemble a packet.
 * @param packet_hdr Where the packet is assembled at.
 * @param src_addr The source address of the packet.
 * @param dst_addr The destination address of the packet.
 * @param entries The routing table entries.
 * @param num_entries The number of routing table entries. It shouldn't be bigger than RIPNG_MAX_RTE_NUM.
 * @return The size of the packet.
 * @author Eason Liu
 *
 */
int assemble(struct packet_hdr *packet_hdr, struct ip6_addr *src_addr, struct ip6_addr *dst_addr, struct ripng_rte *entries, int num_entries){
    packet_hdr->ether.padding = 0;
    packet_hdr->ether.ethertype = 0x86dd;
    packet_hdr->ip6.version = 6;
    packet_hdr->ip6.traffic_class = 0;
    packet_hdr->ip6.flow_label = 0;
    packet_hdr->ip6.next_header = IPPROTO_UDP;
    packet_hdr->ip6.hop_limit = 64;
    for(int i = 0; i < 4; i++){
        packet_hdr->ip6.src_addr.s6_addr32[i] = htonl(src_addr->s6_addr32[i]);
        packet_hdr->ip6.dst_addr.s6_addr32[i] = htonl(dst_addr->s6_addr32[i]);
    }
    packet_hdr->udp.src_port = packet_hdr->udp.dst_port = htons(UDP_PORT_RIPNG);
    packet_hdr->udp.checksum = 0;
    packet_hdr->ripng.cmd = RIPNG_CMD_RESPONSE;
    packet_hdr->ripng.vers = 1;
    packet_hdr->ripng.reserved = 0;
    struct ripng_rte *rte = (struct ripng_rte *)packet_hdr + PACKET_HDR_LEN;
    int entries_size = 0;
    for(int i = 0; i < num_entries; i++){
        rte->ip6_addr.s6_addr32[0] = htonl(entries[i].ip6_addr.s6_addr32[0]);
        rte->ip6_addr.s6_addr32[1] = htonl(entries[i].ip6_addr.s6_addr32[1]);
        rte->ip6_addr.s6_addr32[2] = htonl(entries[i].ip6_addr.s6_addr32[2]);
        rte->ip6_addr.s6_addr32[3] = htonl(entries[i].ip6_addr.s6_addr32[3]);
        rte->prefix_len = entries[i].prefix_len;
        rte->metric = entries[i].metric;
        rte->route_tag = htons(entries[i].route_tag);
        entries_size += RTE_LEN;
    }
    packet_hdr->ip6.payload_len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN + entries_size);
    packet_hdr->udp.len = htons(UDP_HDR_LEN + RIPNG_HDR_LEN + entries_size);
    return PACKET_HDR_LEN + entries_size;
}

/**
 * @brief Send triggered update.
 * @note  This function will block until the whole routing table is sent.
 * @param src_addr The source address of the packet.
 * @param dst_addr The destination address of the packet.
 * @param entries The routing table entries.
 * @param num_entries The number of routing table entries. If num_entries > RIPNG_MAX_RTE_NUM, split the entries into multiple packets.
 * @author Eason Liu
 *
 */
void send_triggered_update(struct ip6_addr *src_addr, struct ip6_addr *dst_addr, struct ripng_rte *entries, int num_entries){
    if (entries == NULL){
        // TODO: wait for BRAM interfaces.
        // read the entry from each node_addr in memory_rte, check the timer and send them.
    }
    else{
        int start_entrie = 0;
        while((num_entries - start_entrie) > RIPNG_MAX_RTE_NUM){
            int size = assemble((struct packet_hdr*)DMA_BLOCK_RADDR, src_addr, dst_addr, &entries[start_entrie], RIPNG_MAX_RTE_NUM);
            _wait_for_dma();
            _grant_dma_access(DMA_BLOCK_RADDR, size, 0);
            start_entrie += RIPNG_MAX_RTE_NUM;
        }
        int size = assemble((struct packet_hdr*)DMA_BLOCK_RADDR, src_addr, dst_addr, &entries[start_entrie], num_entries - start_entrie);
        _wait_for_dma();
        _grant_dma_access(DMA_BLOCK_RADDR, size, 0);
    }
}

/**
 * @brief Send unsolicited response.
 * @note This function will block until the whole routing table is sent.
 * @author Jason Fu
 *
 */
void send_unsolicited_response()
{
    struct ip6_addr src_addr = {0};
    struct ip6_addr dst_addr = {
        .s6_addr32 = {htonl(0xff020000), 0, 0, htonl(0x00000009)}};
    send_triggered_update(&src_addr, &dst_addr, NULL, 0);
}