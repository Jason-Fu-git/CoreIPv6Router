#ifndef _PROTOCOL_H_
#define _PROTOCOL_H_

#include "stdio.h"
#include "stdint.h"
#include "packet.h"

/**
 * @brief Disassemble the packet and check the correctness of the packet.
 * @param base_addr The base address of the packet.
 * @param length The length of the packet.
 * @return RipngErrorCode The error code of the packet.
 * @author Jason Fu, Eason Liu
 *
 */
RipngErrorCode disassemble(uint32_t base_addr, uint32_t length);

/**
 * @brief Send multicast request.
 * @note This function will only write the packet to the SRAM.
 *  To initiate the DMA transfer, you need to call _grant_dma_access()
 * @author Jason Fu
 *
 */
void send_multicast_request();

/**
 * @brief Send unsolicited response.
 * @note  This function will block until the whole routing table is sent.
 * @author Jason Fu
 *
 */
void send_unsolicited_response(struct ip6_addr *src_addr, struct ip6_addr *dst_addr);


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
void send_triggered_update(struct ip6_addr *src_addr, struct ip6_addr *dst_addr, struct ripng_rte *entries, int num_entries);

#endif