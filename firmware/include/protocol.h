#ifndef _PROTOCOL_H_
#define _PROTOCOL_H_

#include "stdio.h"
#include "stdint.h"
#include "packet.h"

#define MULTICAST_ADDR {htonl(0xff020000), 0, 0, htonl(0x00000009)}
#define PORT_NUM 4

/**
 * @brief Update one memory_rte's validation by checking its timers.
 * @param memory_rte The address of the rte.
 * @return 0 if the rte is NULL, 1 otherwise.
 * @author Eason Liu
 * 
 */
int update_memory_rte(struct memory_rte *memory_rte);

/**
 * @brief Disassemble the packet and check the correctness of the packet.
 * @param 
 * @param base_addr The base address of the packet.
 * @param length The length of the packet.
 * @param port The port the packet is sent from.
 * @return RipngErrorCode The error code of the packet.
 * @author Jason Fu, Eason Liu
 *
 */
RipngErrorCode disassemble(uint32_t base_addr, uint32_t length, uint8_t port);

/**
 * @brief Send multicast request.
 * @note This function will only write the packet to the SRAM.
 *  To initiate the DMA transfer, you need to call _grant_dma_access()
 * @author Jason Fu
 *
 */
void send_multicast_request();

/**
 * @brief Assemble a packet.
 * @param src_addr The source address of the packet.
 * @param dst_addr The destination address of the packet.
 * @param entries The routing table entries.
 * @param num_entries The number of routing table entries. It shouldn't be bigger than RIPNG_MAX_RTE_NUM.
 * @return The size of the packet.
 * @author Eason Liu
 *
 */
int assemble(struct ip6_addr *src_addr, struct ip6_addr *dst_addr, struct ripng_rte *entries, int num_entries);

/**
 * @brief Send triggered update.
 * @note  This function will block until the whole routing table is sent.
 * @param src_addr The source address of the packet.
 * @param dst_addr The destination address of the packet.
 * @param entries The routing table entries.
 * @param num_entries The number of routing table entries. If num_entries > RIPNG_MAX_RTE_NUM, split the entries into multiple packets.
 * @param port The port to send the packet to.
 * @author Eason Liu
 *
 */
void send_triggered_update(struct ip6_addr *src_addr, struct ip6_addr *dst_addr, struct ripng_rte *entries, int num_entries, uint8_t port);

/**
 * @brief Send unsolicited response.
 * @note  This function will block until the whole routing table is sent.
 * @author Jason Fu
 *
 */
void send_unsolicited_response();

#endif