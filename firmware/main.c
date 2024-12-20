#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <uart.h>
#include <dma.h>
#include <ip6.h>
#include <ripng.h>
#include <udp.h>
#include <packet.h>
#include "trie/binary_trie.c"

#define MULTICAST_ADDR "ff02::9"

#define MULTICAST_TIMER (30 * 1000)

// TODO: how to store these two timers?
#define TIMEOUT_TIMER (180 * 1000)
#define GARBAGE_COLLECTION_TIMER (120 * 1000)

#define N_IFACE_ON_BOARD 4
#define RIPNG_MAX_RTE 72

extern uint32_t _bss_begin[];
extern uint32_t _bss_end[];

extern RipngErrorCode disassemble(uint32_t base_addr, uint32_t length);

// TODO: This function
void construct_ip6_hdr(struct ip6_hdr* ip6, uint16_t plen){
    ip6->version = 6;
    ip6->traffic_class;
    ip6->flow_label;
    ip6->payload_len = htons(plen);
    ip6->next_header = 17;
    ip6->hop_limit;
    ip6->src_addr;
    ip6->dst_addr;
}

void start(void)
{
    for (uint32_t *p = _bss_begin; p != _bss_end; ++p)
    {
        *p = 0;
    }

    init_uart();

    // TODO: Initialize timers
    uint32_t last_time;
    
    // TODO: Maybe we need to put these to protocol.c
    int has_output = 0;

    // TODO: Initialize addr config and direct route.
    
    // TODO: Send multicast request.

    has_output = 1;
    
    // Main loop
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




        // Main loop starts here, above will be deleted.
        int last_time, now_time; // TODO: how to get the time?
        int dma_res;
        dma_res = _check_dma_busy();
        if (dma_res == 0){ // not busy
            if(has_output){
                int output_size = _get_dma_data_width(); // TODO: Related to output logic
                _grant_dma_access(DMA_BLOCK_ADDR, output_size, 0);
            }
            else{
                _grant_dma_access(DMA_BLOCK_ADDR, MTU, 1);
            }
            continue;
        } 
        else if (dma_res == 1){ // out
            dma_res = _check_dma_ack();
            if (dma_res == 1){ // ack
                continue;
            }
            // else, branch to garbage_collection
        }
        else{ // in
            dma_res = _check_dma_ack();
            if (dma_res == 1){ // ack
                if (has_output){
                    int output_size = _get_dma_data_width(); // TODO: Related to output logic
                    _grant_dma_access(DMA_BLOCK_ADDR, output_size, 0);
                }
                RipngErrorCode error = disassemble(DMA_BLOCK_ADDR, data_width);
                // TODO: Proceed the packet, handle the response/trigger a response in disassemble function.
                if (error != SUCCESS){
                    printf("Error: %d\n", error);
                    // branch to garbage_collection
                }
            }
            // else, branch to garbage_collection
        }
        // TODO: check garbage_collection timer

        // TODO: delete some entries

        // TODO: check multicast timer
        
        if (now_time > last_time + MULTICAST_TIMER){
            // TODO: send unsolicited response

            // TODO: set output request

            last_time = now_time;
            continue;
        }
        // TODO: check entry_timeout timer

        // TODO: launch garbage_collection timer, set the metric to 16

        // TODO: send triggered response

        // TODO: set output request

    }
}
