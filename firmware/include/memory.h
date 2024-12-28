#ifndef _MEMORY_H_
#define _MEMORY_H_

#include <stdint.h>
#include <packet.h>
#include <ip6.h>

#define BRAM_BUFFER_FENCE_ADDR 0x30000000 // TODO: Replace with the actual address

#define IP_CONFIG_BASE_ADDR 0x40000000
#define MAC_CONFIG_BASE_ADDR 0x40001000
#define NEXTHOP_TABLE_BASE_ADDR 0x41000000

#define NUM_MEMORY_RTE 250000

struct memory_rte
{
    struct ip6_addr ip6_addr;
    uint8_t prefix_len;
    uint8_t metric; // == 16 ? timer = GC timer : Timeout timer
    uint8_t nexthop_port; // Upper 1 bit: valid; Lower 5 bits: port number
    uint8_t lower_timer;
};

/**
 * @brief Write data to the IP configuration memory
 * @param ip_addr IP address to be written
 * @param base_addr Base address of the memory
 *
 */
inline void write_ip_addr(struct ip6_addr *ip_addr, uint32_t base_addr)
{
    for (int i = 0; i < 4; i++)
    {
        *((volatile uint32_t *)(base_addr + (i << 2))) = ip_addr->s6_addr32[i];
    }
}

/**
 * @brief Read data from the IP configuration memory
 * @param base_addr Base address of the memory
 * @return IP address read from the memory
 *
 */
inline struct ip6_addr read_ip_addr(uint32_t base_addr)
{
    struct ip6_addr ip_addr;
    for (int i = 0; i < 4; i++)
    {
        ip_addr.s6_addr32[i] = *((volatile uint32_t *)(base_addr + (i << 2)));
    }
    return ip_addr;
}

/**
 * @brief Write data to the MAC configuration memory
 * @param mac_addr MAC address to be written
 * @param base_addr Base address of the memory
 *
 */
inline void write_mac_addr(struct ether_addr *mac_addr, uint32_t base_addr)
{
    *((volatile uint32_t *)(base_addr)) = mac_addr->ether_addr16[0] | (mac_addr->ether_addr16[1] << 16);
    *((volatile uint32_t *)(base_addr + 4)) = mac_addr->ether_addr16[2];
}

/**
 * @brief Read data from the MAC configuration memory
 * @param base_addr Base address of the memory
 * @return MAC address read from the memory
 *
 */
inline struct ether_addr read_mac_addr(uint32_t base_addr)
{
    struct ether_addr mac_addr;
    mac_addr.ether_addr16[0] = *((volatile uint32_t *)(base_addr));
    mac_addr.ether_addr16[1] = *((volatile uint32_t *)(base_addr)) >> 16;
    mac_addr.ether_addr16[2] = *((volatile uint32_t *)(base_addr + 4));
    return mac_addr;
}


/**
 * @brief Write data to the next hop table memory
 * @param ip_addr IP address to be written
 * @param base_addr Base address of the memory
 *
 */
inline void write_nexthop_table(struct ip6_addr *ip_addr, uint32_t base_addr){
    for (int i = 0; i < 4; i++)
    {
        *((volatile uint32_t *)(base_addr + (i << 2))) = ip_addr->s6_addr32[i];
    }
}


/**
 * @brief Read data from the next hop table memory
 * @param base_addr Base address of the memory
 * @return IP address read from the memory
 *
 */
inline struct ip6_addr read_nexthop_table(uint32_t base_addr){
    struct ip6_addr ip_addr;
    for (int i = 0; i < 4; i++)
    {
        ip_addr.s6_addr32[i] = *((volatile uint32_t *)(base_addr + (i << 2)));
    }
    return ip_addr;
}

#endif // _MEMORY_H_
