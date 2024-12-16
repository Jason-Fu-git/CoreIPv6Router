#ifndef _IP6_H_
#define _IP6_H_

#include "stdint.h"

// NOTE: ALL THE MACROS AND STRUCTURES ARE IN NETWORK BYTE ORDER
// Macros for IPv6 header fields
#define IP6_VERSION_OFFSET 0
#define IP6_PAYLOAD_LEN_OFFSET 4
#define IP6_NEXT_HEADER_OFFSET 6
#define IP6_HOP_LIMIT_OFFSET 7

#define IP6_SRC_ADDR_OFFSET 8
#define IP6_DST_ADDR_OFFSET 24

#define IP6_HDR_LEN 40

// protocol numbers
#define IPPROTO_UDP 17

// IPv6 Address
struct ip6_addr
{
    union
    {
        uint8_t __u6_addr8[16];
        uint16_t __u6_addr16[8];
        uint32_t __u6_addr32[4];
    } __in6_u;
#define s6_addr8 __in6_u.__u6_addr8
#define s6_addr16 __in6_u.__u6_addr16
#define s6_addr32 __in6_u.__u6_addr32
};

// IPv6 header
struct ip6_hdr
{
    uint8_t version;
    uint8_t traffic_class;
    uint16_t flow_label;
    uint16_t payload_len;
    uint8_t next_header;
    uint8_t hop_limit;
    struct ip6_addr src_addr;
    struct ip6_addr dst_addr;
};

#endif // _IP6_H_
