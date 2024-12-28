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

extern uint32_t _bss_begin[];
extern uint32_t _bss_end[];
extern uint32_t multicast_timer_ldata;
extern uint32_t multicast_timer_hdata;
extern volatile struct memory_rte memory_rte[NUM_MEMORY_RTE];

void start(void)
{
    // Initialize the .bss section
    for (uint32_t *p = _bss_begin; p != _bss_end; ++p)
    {
        *p = 0;
    }

    // Initialize the UART
    init_uart();

    // Initialize RTEs

    // TODO: Dis-comment this part
    // for (int i = 0; i < NUM_MEMORY_RTE; i++)
    // {
    //     memory_rte[i].node_addr = 0;
    // }

    // Initialize timers
    *((volatile uint32_t *)MTIMECMP_HADDR) = 0xFFFFFFFF;
    *((volatile uint32_t *)MTIMECMP_LADDR) = 0xFFFFFFFF;

    *((volatile uint32_t *)MTIME_HADDR) = 0;
    *((volatile uint32_t *)MTIME_LADDR) = 0;

    // Initialize multicast timer
    multicast_timer_ldata = *((volatile uint32_t *)MTIME_LADDR);
    multicast_timer_hdata = *((volatile uint32_t *)MTIME_HADDR);

    *(volatile uint32_t *)DMA_OUT_LENGTH = 0;

    // Configurate the MAC and IP addresses
    struct ip6_addr ip_addr0 = {
        .s6_addr32 = {0x000080fe, 0, 0xff641f8e, 0x541069fe}};
    struct ip6_addr ip_addr1 = {
        .s6_addr32 = {0x000080fe, 0, 0xff641f8e, 0x551069fe}};
    struct ip6_addr ip_addr2 = {
        .s6_addr32 = {0x000080fe, 0, 0xff641f8e, 0x561069fe}};
    struct ip6_addr ip_addr3 = {
        .s6_addr32 = {0x000080fe, 0, 0xff641f8e, 0x571069fe}};
    struct ether_addr mac_addr0 = {
        .ether_addr16 = {0x1f8c, 0x6964, 0x5410}};
    struct ether_addr mac_addr1 = {
        .ether_addr16 = {0x1f8c, 0x6964, 0x5510}};
    struct ether_addr mac_addr2 = {
        .ether_addr16 = {0x1f8c, 0x6964, 0x5610}};
    struct ether_addr mac_addr3 = {
        .ether_addr16 = {0x1f8c, 0x6964, 0x5710}};
    write_mac_addr(&mac_addr0, MAC_CONFIG_ADDR(0));
    write_mac_addr(&mac_addr1, MAC_CONFIG_ADDR(1));
    write_mac_addr(&mac_addr2, MAC_CONFIG_ADDR(2));
    write_mac_addr(&mac_addr3, MAC_CONFIG_ADDR(3));
    write_ip_addr(&ip_addr0, IP_CONFIG_ADDR(0));
    write_ip_addr(&ip_addr1, IP_CONFIG_ADDR(1));
    write_ip_addr(&ip_addr2, IP_CONFIG_ADDR(2));
    write_ip_addr(&ip_addr3, IP_CONFIG_ADDR(3));

    // TODO: Configurate direct route

    // Send multicast request.
    send_multicast_request();
    // Grant DMA access (Read) to the memory
    _grant_dma_access(DMA_BLOCK_RADDR, *(volatile uint32_t *)DMA_OUT_LENGTH, 0);
    // Wait for the DMA to finish
    _wait_for_dma();
    *(volatile uint32_t *)DMA_CPU_STB = 0;
    // Reset the out length
    *(volatile uint32_t *)DMA_OUT_LENGTH = 0;
    // Grant DMA access (Write) to the memory
    _grant_dma_access(DMA_BLOCK_WADDR, MTU, 1);

    printf("Initialization complete\n");

    // Main loop
    while (true)
    {
        // Main loop starts here, above will be deleted.
        int dma_res = _check_dma_busy();
        uint32_t out_length = *(volatile uint32_t *)DMA_OUT_LENGTH;
        if (dma_res == 0)
        { // not busy
            if (out_length)
                _grant_dma_access(DMA_BLOCK_RADDR, out_length, 0);
            else
                _grant_dma_access(DMA_BLOCK_WADDR, MTU, 1);
            // Reset the out length
            *(volatile uint32_t *)DMA_OUT_LENGTH = 0;
            continue;
        }
        else if (dma_res == 1)
        { // out
            if (_check_dma_ack())
            { // ack
                *(volatile uint32_t *)DMA_CPU_STB = 0;
                continue;
            }
        }
        else // == 2
        {    // in
            if (_check_dma_ack())
            { // ack
                *(volatile uint32_t *)DMA_CPU_STB = 0;
                uint32_t data_width = *(volatile uint32_t *)DMA_CPU_DATA_WIDTH;

                // Make DMA busy
                out_length = *(volatile uint32_t *)DMA_OUT_LENGTH;
                if (out_length)
                    _grant_dma_access(DMA_BLOCK_RADDR, out_length, 0);
                // Reset the out length
                *(volatile uint32_t *)DMA_OUT_LENGTH = 0;

                // Process the packet
                RipngErrorCode error = disassemble(DMA_BLOCK_WADDR, data_width);
                if (error != SUCCESS)
                {
                    printf("Error: %d\n", error);
                }
                else // If SUCCESS, we should continue
                {
                    continue;
                }
            }
        }

        // check multicast timer (should be less than 80s)
        if (check_timeout(MULTICAST_TIME_LIMIT, 0,
                          multicast_timer_ldata, multicast_timer_hdata))
        {
            // Send multicast request.
            send_unsolicited_response();
            // Reset the multicast timer
            multicast_timer_ldata = *((volatile uint32_t *)MTIME_LADDR);
            multicast_timer_hdata = *((volatile uint32_t *)MTIME_HADDR);
        }
    }
}
