#include "dma.h"
#include "stdint.h"

/**
 * @brief Grant the DMA access to the memory
 *
 */
void _grant_dma_access(uint32_t address, uint32_t size, uint32_t write_enable)
{
    *((volatile uint32_t *)DMA_CPU_ADDR) = address;
    *((volatile uint32_t *)DMA_CPU_DATA_WIDTH) = size;
    *((volatile uint32_t *)DMA_CPU_WE) = write_enable;
    *((volatile uint32_t *)DMA_CPU_STB) = 1;
}

/**
 * @brief Wait for the DMA to finish
 *
 */
void _wait_for_dma()
{
    while (*((volatile uint32_t *)DMA_ACK) == 0)
        ;
    *((volatile uint32_t *)DMA_CPU_STB) = 0;
}

/**
 * @brief Get the write data width of the DMA (in bytes)
 *
 */
int _get_dma_data_width()
{
    return *((volatile uint32_t *)DMA_DATA_WIDTH);
}
