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
        {.s6_addr32 = {0x000080fe, 0, 0xff641f8e, 0x541069fe}},
        {.s6_addr32 = {0x000080fe, 0, 0xff641f8e, 0x551069fe}},
        {.s6_addr32 = {0x000080fe, 0, 0xff641f8e, 0x561069fe}},
        {.s6_addr32 = {0x000080fe, 0, 0xff641f8e, 0x571069fe}}
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

    // config_direct_route();

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
    _grant_dma_access(DMA_BLOCK_WADDR, MTU, 1);

    // Main loop
    while (true)
    {
        int dma_res = _check_dma_busy();
        uint32_t out_length = *(volatile uint32_t *)DMA_OUT_LENGTH;
        if (dma_res == 0)
        { // not busy
            if (out_length)
                _grant_dma_access(DMA_BLOCK_RADDR, out_length, 0);
            else if (*(volatile uint32_t *)DMA_IN_VALID)
                _grant_dma_access(DMA_BLOCK_WADDR, MTU, 1);
            // Reset the out length
            *(volatile uint32_t *)DMA_OUT_LENGTH = 0;
            continue;
        }
        else if (dma_res == 1)
        { // out
            if (_check_dma_ack())
            { // ack
                continue;
            }
        }
        else // == 2
        {    // in
            if (_check_dma_ack())
            { // ack
                *(volatile uint32_t *)DMA_CPU_STB = 0;
                uint32_t data_width = *(volatile uint32_t *)DMA_DATA_WIDTH;
                uint8_t port_id = *(volatile uint8_t *)DMA_IN_PORT_ID;
                
                // Make DMA busy
                out_length = *(volatile uint32_t *)DMA_OUT_LENGTH;
                if (out_length)
                    _grant_dma_access(DMA_BLOCK_RADDR, out_length, 0);
                // Reset the out length
                *(volatile uint32_t *)DMA_OUT_LENGTH = 0;

                // Process the packet
                RipngErrorCode error = disassemble(DMA_BLOCK_WADDR, data_width, port_id);
                if (error != SUCCESS)
                {
                    printf("D%d", error);
                    _putchar('\0');
                }
                else // If SUCCESS, we should continue
                {
                    continue;
                }
            }
        }

        // check multicast timer (30s)
        if (check_timeout(MULTICAST_TIME_LIMIT, multicast_timer_ldata))
        {
            // Send multicast request.
            send_unsolicited_response();
            // Reset the multicast timer
            multicast_timer_ldata = *((volatile uint32_t *)MTIME_LADDR);
        }
    }
}
