#ifndef _UDP_H_
#define _UDP_H_

#include "stdint.h"
// NOTE: ALL THE MACROS AND STRUCTURES ARE IN NETWORK BYTE ORDER
// Macros for UDP header fields
#define UDP_HDR_LEN 8

#define UDP_SRC_PORT_OFFSET 0
#define UDP_DST_PORT_OFFSET 2
#define UDP_LEN_OFFSET 4
#define UDP_CHECKSUM_OFFSET 6

// UDP port numbers
#define UDP_PORT_RIPNG 521

struct udp_hdr
{
    uint16_t src_port;
    uint16_t dst_port;
    uint16_t len;
    uint16_t checksum;
};


#endif // _UDP_H_
