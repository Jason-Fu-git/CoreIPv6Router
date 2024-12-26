#ifndef _DMA_H_
#define _DMA_H_

#define DMA_CPU_STB 0x01000000
#define DMA_CPU_WE 0x01000004
#define DMA_CPU_ADDR 0x01000008
#define DMA_CPU_DATA_WIDTH 0x0100000C
#define DMA_ACK 0x01000010
#define DMA_DATA_WIDTH 0x01000014
#define DMA_CHECKSUM 0x01000018
#define DMA_PORT_ID 0x0100001C

#define DMA_BLOCK_WADDR 0x80600000
#define DMA_BLOCK_RADDR 0x80610000

#define DMA_OUT_LENGTH 0x80620000

#include "stdint.h"

/**
 * @brief Grant the DMA access to the memory
 *
 */
inline void _grant_dma_access(uint32_t address, uint32_t size, uint32_t write_enable)
{
    // write_enable: 1 for in, 0 for out
    *((volatile uint32_t *)DMA_CPU_ADDR) = address;
    *((volatile uint32_t *)DMA_CPU_DATA_WIDTH) = size;
    *((volatile uint32_t *)DMA_CPU_WE) = write_enable;
    *((volatile uint32_t *)DMA_CPU_STB) = 1;
}

/**
 * @brief Wait for the DMA to finish
 * @note This function is blocking, and will not return until the DMA is done.
 * You should reset STB after this function returns.
 *
 */
inline void _wait_for_dma()
{
    while (*((volatile uint32_t *)DMA_ACK) == 0)
    {
    }
}

/**
 * @brief Check what the DMA is busy with
 * 0 for idle, 1 for out, 2 for in
 */
inline int _check_dma_busy()
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
inline int _check_dma_ack()
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
inline int _get_dma_data_width()
{
    return *((volatile uint32_t *)DMA_DATA_WIDTH);
}

#endif // _DMA_H_