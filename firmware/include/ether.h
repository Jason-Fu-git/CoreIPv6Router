#ifndef _ETHER_H_
#define _ETHER_H_

#include "stdint.h"

#define PADDING 0
#define ETHER_HDR_LEN 14

// Ethernet address
struct ether_addr
{
    union
    {
        uint8_t __ea_addr8[6];
        uint16_t __ea_addr16[3];
    } __ea_u;
#define ether_addr8 __ea_u.__ea_addr8
#define ether_addr16 __ea_u.__ea_addr16
};

// Ethernet header
struct ether_hdr
{
    uint16_t padding = 0;
    struct ether_addr dst_addr;
    struct ether_addr src_addr;
    uint16_t ethertype;
};

#endif // _ETHER_H_
