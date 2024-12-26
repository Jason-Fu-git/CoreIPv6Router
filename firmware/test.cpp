#include <cstdio>
#include <cstdint>

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

struct rte
{
    struct ip6_addr ip6_addr;
    uint16_t route_tag;
    uint8_t prefix_len;
    uint8_t metric;
};

int main()
{
    uint32_t data[] = {0xFE800000, 0x00000000, 0x8E1F64FF, 0xFE691001, 0x01400000};
    struct rte *rte = (struct rte *)data;
    printf("Route Tag: %x\n", rte->route_tag);
    printf("Prefix Length: %x\n", rte->prefix_len);
    printf("Metric: %x\n", rte->metric);
}