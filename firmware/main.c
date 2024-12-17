#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <uart.h>
#include <dma.h>

extern uint32_t _bss_begin[];
extern uint32_t _bss_end[];

void start(void)
{
    for (uint32_t *p = _bss_begin; p != _bss_end; ++p)
    {
        *p = 0;
    }

    init_uart();

    // FIXME: DMA Test
    while (true){
        // Grant DMA access (write) to the memory
        _grant_dma_access(DMA_BLOCK_ADDR, 80, 1);
        // Wait for the DMA to finish
        _wait_for_dma();
        // Get the write data width of the DMA (in bytes)
        int data_width = _get_dma_data_width();

        uint32_t ip6_src[4];
        uint32_t ip6_dst[4];

        // Read the data from the Memory
        for (int i = 0; i < 4; i++){
            ip6_src[i] = *((uint32_t *)(DMA_BLOCK_ADDR + 24 + i * 4));
            ip6_dst[i] = *((uint32_t *)(DMA_BLOCK_ADDR + 40 + i * 4));
        }

        // Swap the source and destination IP addresses
        for (int i = 0; i < 4; i++){
            *((uint32_t *)(DMA_BLOCK_ADDR + 24 + i * 4)) = ip6_dst[i];
            *((uint32_t *)(DMA_BLOCK_ADDR + 40 + i * 4)) = ip6_src[i];
        }

        // Reset the checksum
        uint32_t checksum = *((uint32_t *)(DMA_BLOCK_ADDR + 60));
        checksum = checksum & 0x0000FFFF;
        *((uint32_t *)(DMA_BLOCK_ADDR + 60)) = checksum;

        asm volatile("fence.i");

        // Grant DMA access (read) to the memory
        _grant_dma_access(DMA_BLOCK_ADDR, data_width, 0);
        // Wait for the DMA to finish
        _wait_for_dma();
    }
}
