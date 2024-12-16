#ifndef _RIPNG_H_
#define _RIPNG_H_

#include "stdint.h"
#include "ip6.h"
// NOTE: ALL THE MACROS AND STRUCTURES ARE IN NETWORK BYTE ORDER
// Macros for RIPng header fields
#define RIPNG_HDR_LEN 4
#define RIPNG_CMD_OFFSET 0
#define RIPNG_VERS_OFFSET 1
#define RIPNG_RESERVED_OFFSET 2

// RIPng command types
#define RIPNG_CMD_REQUEST 1
#define RIPNG_CMD_RESPONSE 2

struct ripng_hdr
{
    uint8_t cmd;
    uint8_t vers;
    uint16_t reserved;
};

// RTE
#define RTE_LEN 20

#define RTE_IP6_ADDR_OFFSET 0
#define RTE_ROUTE_TAG_OFFSET 16
#define RTE_PREFIX_LEN_OFFSET 18
#define RTE_METRIC_OFFSET 19

struct rte
{
    struct ip6_addr ip6_addr;
    uint16_t route_tag;
    uint8_t prefix_len;
    uint8_t metric;
};

#endif // _RIPNG_H_
