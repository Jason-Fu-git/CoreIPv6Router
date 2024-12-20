// RIPng protocol implementation
#include "stdio.h"
#include "stdint.h"
#include "packet.h"

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
    // FIXME: OUR CPU DOES NOT SUPPORT MOD OPERATION
    // if ((udp_len - UDP_HDR_LEN - RIPNG_HDR_LEN) % 20 != 0)
    // {
    //     return ERR_LENGTH;
    // }
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
    // FIXME: OUR CPU DOES NOT SUPPORT DIVISION OPERATION
    // int entry_num = (udp_len - 8 - 4) / 20;
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

        if (ripng_hdr->cmd == RIPNG_CMD_REQUEST){
            // TODO: Handle the request
        }
        else{
            // TODO: check the route table and trigger the update
        }

        // increment the length and index
        len += 20;
        i++;
    }

    return SUCCESS;
}
