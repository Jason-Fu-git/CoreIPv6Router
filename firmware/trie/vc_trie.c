//
// Created by Yusaki on 24-12-17.
//

#include <stdint.h>
#include <stdbool.h>
#include "bram.h"

static const uint32_t VC_ENTRY_INVALID = 31;
static const uint32_t MAX_PREFIX_LENGTH = 28;

extern TrieAddr BRAMAddr(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);
extern TrieAddr BRAMAddrVCAddOffset(TrieAddr, uint32_t, uint32_t);

typedef struct {
	uint32_t prefix_length;
	uint32_t prefix;
	uint32_t next_hop;
} VCEntry;

typedef struct {
	uint32_t lc;
	uint32_t rc;
	VCEntry bin[1];
} VCNode1;

typedef struct {
	uint32_t lc;
	uint32_t rc;
	VCEntry bin[7];
} VCNode7;

typedef struct {
	uint32_t lc;
	uint32_t rc;
	VCEntry bin[15];
} VCNode15;

typedef struct {
	uint32_t lc;
	uint32_t rc;
	VCEntry bin[14];
} VCNode14;

typedef struct {
	uint32_t lc;
	uint32_t rc;
	VCEntry bin[10];
} VCNode10;

TrieAddr NodeAddrToPhys(uint32_t node_addr, uint32_t trie_index) {
	return BRAMAddr(trie_index, TRIE_TYPE_VC, node_addr, 0, 0);
}

void VCWriteNode1ToBRAM(VCNode1 node, TrieAddr addr) {
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_LC) = node.lc;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_RC) = node.rc;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX_LENGTH) = node.bin[0].prefix_length;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX) = node.bin[0].prefix;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_NEXT_HOP) = node.bin[0].next_hop;
}

typedef struct {
	uint32_t node_count;
	uint32_t node_num[16];
	uint32_t excessive_count;
} VCTrieMeta;

typedef struct {
	VCNode1 root;  // root must contain default route
	VCTrieMeta meta;
} VCTrie;

void VCTrieInit(VCTrie* trie) {
	trie->meta.node_count = 0;
	trie->meta.node_num[0] = 2;
	for (int i = 1; i < 16; ++i) {
		trie->meta.node_num[i] = 0;
	}
	trie->meta.excessive_count = 0;
	trie->root.lc = 0;
	trie->root.rc = 0;
	trie->root.bin[0].prefix_length = 0;
	trie->root.bin[0].prefix = 0;
	trie->root.bin[0].next_hop = 0;
}

TrieAddr VCTrieNewNode(VCTrie* trie, uint32_t level) {
	TrieAddr addr = BRAMAddr(level >> 3, TRIE_TYPE_VC, trie->meta.node_num[level >> 3], 0, 0);
	trie->meta.node_num[level >> 3]++;
	return addr;
}

void _VCTrieTryCreateSubtree(VCTrie* trie, TrieAddr node, uint32_t level, uint32_t index) {
	if ()
}

bool VCTrieInsert(VCTrie* trie, VCEntry entry) {
	uint32_t level = 0;
	uint32_t prefix = entry.prefix;
	TrieAddr now = &(trie->root);
	while (entry.prefix_length - level > MAX_PREFIX_LENGTH) {

	}

	trie->meta.excessive_count++;
	return false;
}
