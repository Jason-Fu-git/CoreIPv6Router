#include "include/memory.h"

volatile struct memory_rte memory_rte[NUM_MEMORY_RTE];
int rte_map[NUM_TRIE_NODE];
int spare_nexthop_index = 0;
int spare_memory_index = 0;