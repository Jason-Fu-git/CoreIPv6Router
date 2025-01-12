#ifndef _PROTOCOL_H_
#define _PROTOCOL_H_

#include "stdio.h"
#include "stdint.h"
#include "packet.h"

#define MULTICAST_ADDR {htonl(0xff020000), 0, 0, htonl(0x00000009)}
#define PORT_NUM 4

/**
 * @brief Put a direct route into the routing table.
 * @param ip6_addr The IP address of the direct route.
 * @param prefix_len The prefix length of the direct route.
 * @param port The port ID of the direct route.
 * @author Eason Liu
 */
void config_direct_route(struct ip6_addr *ip6_addr, uint8_t prefix_len, uint8_t port);

/**
 * @brief Update one memory_rte's validation by checking its timers.
 * @param memory_rte_v The address of the rte.
 * @return 0 if the rte is NULL, 1 otherwise.
 * @author Eason Liu
 */
int update_memory_rte(void *memory_rte_v);

/**
 * @brief Disassemble the packet and check the correctness of the packet.
 * @param base_addr The base address of the packet.
 * @param length The length of the packet.
 * @param port The port the packet is sent from.
 * @return RipngErrorCode The error code of the packet.
 * @author Jason Fu, Eason Liu
 */
RipngErrorCode disassemble(uint32_t base_addr, uint32_t length, uint8_t port);

/**
 * @brief Send multicast request.
 * @note This function will only write the packet to the SRAM.
 *  To initiate the DMA transfer, you need to call _grant_dma_access()
 * @param port The port to send the packet to.
 * @author Jason Fu, Eason Liu
 */
void send_multicast_request(int port);

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
int assemble(void *src_addr_v, void *dst_addr_v, void *entries_v, int num_entries, uint8_t port, uint8_t is_multicast);

/**
 * @brief Send triggered update.
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
void send_response(void *src_addr_v, void *dst_addr_v, void *entries_v, int num_entries, uint8_t port, uint8_t is_multicast);

/**
 * @brief Send unsolicited response.
 * @note  This function will block until the whole routing table is sent.
 * @author Jason Fu
 */
void send_unsolicited_response();

#endif