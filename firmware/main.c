#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <uart.h>
#include <dma.h>
#include "packet.h"

extern uint32_t _bss_begin[];
extern uint32_t _bss_end[];
extern RipngErrorCode disassemble(uint32_t base_addr, uint32_t length);

void start(void)
{
    for (uint32_t *p = _bss_begin; p != _bss_end; ++p)
    {
        *p = 0;
    }

    init_uart();

    // FIXME: DMA Test
    while (true)
    {
        // Grant DMA access (write) to the memory
        _grant_dma_access(DMA_BLOCK_ADDR, MTU, 1);
        // Wait for the DMA to finish
        _wait_for_dma();
        // Get the write data width of the DMA (in bytes)
        uint32_t data_width = _get_dma_data_width();
        // Get the calculated checksum
        uint32_t checksum = *(volatile uint32_t *)DMA_CHECKSUM;
        if (checksum != 0)
        {
            printf("Error: checksum = %d\n", checksum);
            continue;
        }
        // Disassemble the packet
        RipngErrorCode error = disassemble(DMA_BLOCK_ADDR, data_width);
        if (error != SUCCESS)
        {
            printf("Error: %d\n", error);
            continue;
        }
        asm volatile("fence.i");
        // Grant DMA access (read) to the memory
        _grant_dma_access(DMA_BLOCK_ADDR, data_width, 0);
        // Wait for the DMA to finish
        _wait_for_dma();
    }
}
