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
    for (int i = 0; i < NUM_MEMORY_RTE; i++)
    {
        memory_rte[i].node_addr = 0;
    }

    // Initialize timers
    *((volatile uint32_t *)MTIMECMP_HADDR) = 0xFFFFFFFF;
    *((volatile uint32_t *)MTIMECMP_LADDR) = 0xFFFFFFFF;

    *((volatile uint32_t *)MTIME_HADDR) = 0;
    *((volatile uint32_t *)MTIME_LADDR) = 0;

    // Initialize multicast timer
    multicast_timer_ldata = *((volatile uint32_t *)MTIME_LADDR);
    multicast_timer_hdata = *((volatile uint32_t *)MTIME_HADDR);

    *(volatile uint32_t *)DMA_OUT_LENGTH = 0;

    // TODO: Initialize addr config and direct route.

    // Send multicast request.
    send_multicast_request();
    // Grant DMA access (Read) to the memory
    _grant_dma_access(DMA_BLOCK_RADDR, DMA_OUT_LENGTH, 0);
    // Wait for the DMA to finish
    _wait_for_dma();
    *(volatile uint32_t *)DMA_CPU_STB = 0;
    // Reset the out length
    *(volatile uint32_t *)DMA_OUT_LENGTH = 0;
    // Grant DMA access (Write) to the memory
    _grant_dma_access(DMA_BLOCK_WADDR, MTU, 1);

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
