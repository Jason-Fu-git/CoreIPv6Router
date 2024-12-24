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

// RIPng header
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

struct ripng_rte
{
    struct ip6_addr ip6_addr;
    uint16_t route_tag;
    uint8_t prefix_len;
    uint8_t metric;
};

// Error codes
// 如果同时出现多种错误，返回满足下面错误描述的第一条错误
// The return value of the disassemble function is defined as follows
// If multiple errors occur at the same time, the first error that satisfies the
// following error description is returned
typedef enum
{
    // 没有错误
    // No errors
    SUCCESS = 0,
    // IPv6 头中 next header 字段不是 UDP 协议
    // The next header field in the IPv6 header is not UDP protocol
    ERR_IPV6_NEXT_HEADER_NOT_UDP,
    // UDP 头中源端口号或者目的端口号不是 521(RIPng)
    // The source or destination port number in the UDP header is not 521 (RIPng)
    ERR_UDP_PORT_NOT_RIPNG,
    // IPv6 头、UDP 头和实际的 RIPng 路由项的长度出现错误或者不一致
    // The length of the IPv6 header, UDP header and the actual RIPng routing
    // entry are incorrect or do not match
    ERR_LENGTH,
    // RIPng 的 Command 字段错误
    // The Command field of RIPng is wrong
    ERR_RIPNG_BAD_COMMAND,
    // RIPng 的 Version 字段错误
    // The Version field of RIPng is wrong
    ERR_RIPNG_BAD_VERSION,
    // RIPng 的 Zero（Reserved）字段错误
    // The Zero(Reserved) field of RIPng is wrong
    ERR_RIPNG_BAD_ZERO,
    // RIPng 表项的 Metric 字段错误
    // Wrong Metric field in RIPng table entry
    ERR_RIPNG_BAD_METRIC,
    // RIPng 表项的 Prefix Len 字段错误
    // Wrong Prefix Len field in RIPng table entry
    ERR_RIPNG_BAD_PREFIX_LEN,
    // RIPng 表项的 Route Tag 字段错误
    // Wrong Route Tag field in RIPng table entry
    ERR_RIPNG_BAD_ROUTE_TAG,
    // RIPng 表项的 Prefix 和 Prefix Len 字段不符合要求
    // The Prefix and Prefix Len fields of the RIPng table entry are inconsistent
    ERR_RIPNG_INCONSISTENT_PREFIX_LENGTH,
} RipngErrorCode;

#endif // _RIPNG_H_
