#ifndef _DMA_H_
#define _DMA_H_

#define DMA_CPU_STB 0x01000000
#define DMA_CPU_WE 0x01000004
#define DMA_CPU_ADDR 0x01000008
#define DMA_CPU_DATA_WIDTH 0x0100000C
#define DMA_ACK 0x01000010
#define DMA_DATA_WIDTH 0x01000014

#define DMA_BLOCK_ADDR 0x80200000

#include "stdint.h"

/**
 * @brief Grant the DMA access to the memory
 *
 */
void _grant_dma_access(uint32_t address, uint32_t size, uint32_t write_enable);

/**
 * @brief Wait for the DMA to finish
 *
 */
void _wait_for_dma();

/**
 * @brief Get the write data width of the DMA (in bytes)
 *
 */
int _get_dma_data_width();

#endif // _DMA_H_