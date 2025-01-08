#include "include/memory.h"

struct memory_rte memory_rte[NUM_MEMORY_RTE] __attribute__((section(".data")));
int rte_map[NUM_TRIE_NODE] __attribute__((section(".data")));
int spare_nexthop_index = 0;
int spare_memory_index = 0;
// uint32_t last_triggered_time = 0;