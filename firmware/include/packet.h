#ifndef _PACKET_H_
#define _PACKET_H_

// NOTE: ALL THE MACROS AND STRUCTURES ARE IN NETWORK BYTE ORDER
#include "ip6.h"
#include "udp.h"
#include "ripng.h"
#include "ether.h"


#define MTU 1500
#define RIPNG_MAX_RTE_NUM 72

#define __REVS(x)                              \
    asm volatile("mv a0, %0" ::"r"(x) : "a0"); \
    asm volatile(".word 0x68855513" ::: "a0") // grevi a0, a0, 01000
#define __REVL(x)                              \
    asm volatile("mv a0, %0" ::"r"(x) : "a0"); \
    asm volatile(".word 0x69855513" ::: "a0") // grevi a0, a0, 11000

struct packet_hdr
{
    struct ether_hdr ether;
    struct ip6_hdr ip6;
    struct udp_hdr udp;
    struct ripng_hdr ripng;
};


inline uint32_t htonl(uint32_t hostlong)
{
    __REVL(hostlong);
    uint32_t ret;
    asm volatile("mv %0, a0" : "=r"(ret) : :);
    return ret;
}

inline uint16_t htons(uint16_t hostshort)
{
    uint32_t extended = (uint32_t)hostshort;
    uint32_t ret;
    __REVS(extended);
    asm volatile("mv %0, a0" : "=r"(ret) : :);
    return (uint16_t)ret;
}

inline uint32_t ntohl(uint32_t netlong)
{
    return htonl(netlong);
}

inline uint16_t ntohs(uint16_t netshort)
{
    return htons(netshort);
}

#endif // _PACKET_H_
