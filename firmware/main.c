#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <uart.h>
#include <dma.h>
#include <ip6.h>
#include <ripng.h>
#include <udp.h>
#include <packet.h>
#include <timer.h>
#include <memory.h>
#include <protocol.h>

// Configurate the MAC and IP addresses
struct ip6_addr ip_addrs[PORT_NUM] = {
        {.s6_addr32 = {0x000080fe, 0, 0, 0x50000000}},
        {.s6_addr32 = {0x000080fe, 0, 0, 0x51000000}},
        {.s6_addr32 = {0x000080fe, 0, 0, 0x52000000}},
        {.s6_addr32 = {0x000080fe, 0, 0, 0x53000000}}
};
struct ether_addr mac_addrs[PORT_NUM] = {
        {.ether_addr16 = {0x1f8c, 0x6964, 0x5410}},
        {.ether_addr16 = {0x1f8c, 0x6964, 0x5510}},
        {.ether_addr16 = {0x1f8c, 0x6964, 0x5610}},
        {.ether_addr16 = {0x1f8c, 0x6964, 0x5710}}
};

extern uint32_t _bss_begin[];
extern uint32_t _bss_end[];
extern uint32_t multicast_timer_ldata;
extern struct memory_rte memory_rte[NUM_MEMORY_RTE];
extern void TrieInit();

void start(void)
{
    // Initialize the .bss section
    for (uint32_t *p = _bss_begin; p != _bss_end; ++p)
    {
        *p = 0;
    }

    // Initialize the UART
    init_uart();

    printf("TAC CA[[ F");
    _putchar('\0');

    // Initialize timers
    *((volatile uint32_t *)MTIMECMP_HADDR) = 0xFFFFFFFF;
    *((volatile uint32_t *)MTIMECMP_LADDR) = 0xFFFFFFFF;

    *((volatile uint32_t *)MTIME_HADDR) = 0;
    *((volatile uint32_t *)MTIME_LADDR) = 0;

    // Initialize multicast timer
    multicast_timer_ldata = *((volatile uint32_t *)MTIME_LADDR);

    // Initialize tries
    TrieInit();

    *(volatile uint32_t *)DMA_OUT_LENGTH = 0;

    for(int i = 0; i < PORT_NUM; i++){
        write_ip_addr(ip_addrs + i, IP_CONFIG_ADDR(i));
        write_mac_addr(mac_addrs + i, MAC_CONFIG_ADDR(i));
    }

    struct ip6_addr direct_route;
    direct_route.s6_addr32[0] = htonl(0x2A0EAA06);
    direct_route.s6_addr32[2] = 0;
    direct_route.s6_addr32[3] = 0;
    for(int i = 0; i < 4; i++) {
        direct_route.s6_addr32[1] = htonl(0x04950000 + i);
        config_direct_route(&direct_route, 64, i);
    }

    write_nexthop_table_ip6_addr(&direct_route, NEXTHOP_TABLE_ADDR(5)); 

    // Send multicast request.
    for(int p = 0; p < PORT_NUM; p++){
        // Appoint out port id
        *(volatile uint32_t *)DMA_OUT_PORT_ID = p;
        send_multicast_request(p);
        // Grant DMA access (Read) to the memory
        _grant_dma_access(DMA_BLOCK_RADDR, *(volatile uint32_t *)DMA_OUT_LENGTH, 0);
        // Wait for the DMA to finish
        _wait_for_dma();
        *(volatile uint32_t *)DMA_CPU_STB = 0;
        // Reset the out length
        *(volatile uint32_t *)DMA_OUT_LENGTH = 0;
    }

    printf("I");
    _putchar('\0');

    // Grant DMA access (Write) to the memory
    // _grant_dma_access(DMA_BLOCK_WADDR, MTU, 1);

    // Main loop
    while (true)
    {
        int dma_res = _check_dma_busy();
        if (dma_res == 0)
        { // not busy
            if (check_timeout(MULTICAST_TIME_LIMIT, multicast_timer_ldata)) { // check multicast timer (30s)
                // Send multicast request.
                send_unsolicited_response();
                if(_check_dma_busy()) { _wait_for_dma(); }
                // Reset the multicast timer
                multicast_timer_ldata = *((volatile uint32_t *)MTIME_LADDR);
            }
            else if (*(volatile uint32_t *)DMA_IN_VALID) {
                _grant_dma_access(DMA_BLOCK_WADDR, MTU, 1);
            }
            continue;
        }
        else if (dma_res == 1)
        { // out
            _check_dma_ack();
            continue;
        }
        else // == 2
        {    // in
            if (_check_dma_ack())
            { // ack
                uint32_t data_width = *(volatile uint32_t *)DMA_DATA_WIDTH;
                uint8_t port_id = *(volatile uint8_t *)DMA_IN_PORT_ID;

                // Process the packet
                RipngErrorCode error = disassemble(DMA_BLOCK_WADDR, data_width, port_id);
                if (error != SUCCESS)
                {
                    printf("D%d", error);
                    _putchar('\0');
                }
                // If SUCCESS, we should continue
            }
        }
    }
}
