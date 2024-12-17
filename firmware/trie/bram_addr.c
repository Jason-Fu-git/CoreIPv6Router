//
// Created by Yusaki on 24-12-17.
//

#include <stdint.h>
#include "bram.h"

static const TrieAddr BRAM_BASE = 0x20000000u;

TrieAddr BRAMAddr(uint32_t trie_index, uint32_t trie_type, uint32_t node_index, uint32_t entry_index, uint32_t field) {
	return BRAM_BASE
		+ (trie_index << 24)
		+ (trie_type << 20)
		+ ((node_index >> 12) << 21)
		+ ((node_index & 0xfff) << 8)
		+ (entry_index << 4)
		+ field;
}

TrieAddr BRAMAddrBT(uint32_t trie_index, uint32_t node_index) {
	return BRAM_BASE + (trie_index << 24) + ((node_index >> 12) << 21) + ((node_index & 0xfff) << 8);
}

TrieAddr BRAMAddrVCAddOffset(TrieAddr base, uint32_t entry_index, uint32_t field) {
	return base + (entry_index << 4) + field;
}
