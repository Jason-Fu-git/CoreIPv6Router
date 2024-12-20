#include "dma.h"
#include "stdint.h"

/**
 * @brief Grant the DMA access to the memory
 *
 */
void _grant_dma_access(uint32_t address, uint32_t size, uint32_t write_enable) // write_enable: 1 for in, 0 for out
{
    *((volatile uint32_t *)DMA_CPU_ADDR) = address;
    *((volatile uint32_t *)DMA_CPU_DATA_WIDTH) = size;
    *((volatile uint32_t *)DMA_CPU_WE) = write_enable;
    *((volatile uint32_t *)DMA_CPU_STB) = 1;
}

/**
 * @brief Check what the DMA is busy with
 * 0 for idle, 1 for out, 2 for in
 */
int _check_dma_busy()
{
    if (*((volatile uint32_t *)DMA_CPU_STB) == 1)
    {
        return *((volatile uint32_t *)DMA_CPU_WE) + 1;
    }
    return 0;
}

/**
 * @brief Check if ACK (and release stb)
 */
int _check_dma_ack()
{
    int res = *((volatile uint32_t *)DMA_ACK);
    if (res == 1)
    {
        *((volatile uint32_t *)DMA_CPU_STB) = 0;
    }
    return res;
}

/**
 * @brief Get the write data width of the DMA (in bytes)
 *
 */
int _get_dma_data_width()
{
    return *((volatile uint32_t *)DMA_DATA_WIDTH);
}
