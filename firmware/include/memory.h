#ifndef _MEMORY_H_
#define _MEMORY_H_

#include <stdint.h>

#define BRAM_BUFFER_FENCE_ADDR 0x30000000 // TODO: Replace with the actual address
#define NUM_MEMORY_RTE 250000


struct memory_rte
{
    uint32_t node_addr; // = 0 - invalid
    uint32_t metric; // == 16 ? timer = GC timer :a Timeout timer
    uint32_t lower_timer;
    uint32_t upper_timer;
};


inline void write_vc_memory(uint32_t addr, uint32_t *data, int length)
{
    for (int i = 0; i < length; i++)
    {
        *((volatile uint32_t *)(addr + i << 2)) = data[i];
    }
    *((volatile uint32_t *)(BRAM_BUFFER_FENCE_ADDR)) = 1;
}



#endif