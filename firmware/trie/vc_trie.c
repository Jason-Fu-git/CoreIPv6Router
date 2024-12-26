//
// Created by Yusaki on 24-12-17.
//

#include <stdint.h>
#include <stdbool.h>
#include "bram.h"

static const uint32_t VC_ENTRY_INVALID = 31;
static const uint32_t MAX_PREFIX_LENGTH = 28;

extern TrieAddr BRAMAddr(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);

TrieAddr BRAMAddrVCAddOffset(TrieAddr base, uint32_t entry_index, uint32_t field) {
	return base + (entry_index << 4) + field;
}

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

NodeAddr NodeAddrToPhys(uint32_t node_addr, uint32_t trie_index) {
	return BRAMAddr(trie_index, TRIE_TYPE_VC, node_addr, 0, 0);
}

void VCWriteNode1ToBRAM(VCNode1* node, TrieAddr addr) {
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_LC)            = node->lc;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_RC)            = node->rc;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX_LENGTH) = node->bin[0].prefix_length;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX)        = node->bin[0].prefix;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_NEXT_HOP)      = node->bin[0].next_hop;
}

void VCWriteNode7ToBRAM(VCNode7* node, TrieAddr addr) {
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_LC) = node->lc;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_RC) = node->rc;
	for (uint32_t i = 0; i < 7; ++i) {
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX_LENGTH) = node->bin[i].prefix_length;
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX)        = node->bin[i].prefix;
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_NEXT_HOP)      = node->bin[i].next_hop;
	}
}

void VCWriteNode15ToBRAM(VCNode15* node, TrieAddr addr) {
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_LC) = node->lc;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_RC) = node->rc;
	for (uint32_t i = 0; i < 15; ++i) {
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX_LENGTH) = node->bin[i].prefix_length;
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX)        = node->bin[i].prefix;
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_NEXT_HOP)      = node->bin[i].next_hop;
	}
}

void VCWriteNode14ToBRAM(VCNode14* node, TrieAddr addr) {
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_LC) = node->lc;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_RC) = node->rc;
	for (uint32_t i = 0; i < 14; ++i) {
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX_LENGTH) = node->bin[i].prefix_length;
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX)        = node->bin[i].prefix;
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_NEXT_HOP)      = node->bin[i].next_hop;
	}
}
void VCWriteNode10ToBRAM(VCNode10* node, TrieAddr addr) {
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_LC) = node->lc;
	*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_RC) = node->rc;
	for (uint32_t i = 0; i < 10; ++i) {
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX_LENGTH) = node->bin[i].prefix_length;
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_PREFIX)        = node->bin[i].prefix;
		*(volatile uint32_t*)BRAMAddrVCAddOffset(addr, 0, VCTRIE_ENTRY_FIELD_NEXT_HOP)      = node->bin[i].next_hop;
	}
}

void (*VCWriteNodeToBRAM[])(void*, TrieAddr) = {
VCWriteNode1ToBRAM,
VCWriteNode7ToBRAM,
VCWriteNode15ToBRAM,
VCWriteNode15ToBRAM,
VCWriteNode14ToBRAM,
VCWriteNode10ToBRAM,
VCWriteNode1ToBRAM,
VCWriteNode1ToBRAM,
VCWriteNode1ToBRAM,
VCWriteNode1ToBRAM,
VCWriteNode1ToBRAM,
VCWriteNode1ToBRAM,
VCWriteNode1ToBRAM,
VCWriteNode1ToBRAM,
VCWriteNode1ToBRAM,
VCWriteNode1ToBRAM,
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
	trie->root.bin[0].prefix        = 0;
	trie->root.bin[0].next_hop      = 0;
}

NodeAddr VCTrieNewNode(VCTrie* trie, uint32_t level) {
	NodeAddr addr = BRAMAddr(level >> 3, TRIE_TYPE_VC, trie->meta.node_num[level >> 3], 0, 0);
	trie->meta.node_num[level >> 3]++;
	return addr;
}

void _VCTrieTryCreateSubtree(VCTrie* trie, TrieAddr node, uint32_t level, uint32_t index) {
	switch (level) {
		case 0:  [[fallthrough]]
		case 6:  [[fallthrough]]
		case 7:  [[fallthrough]]
		case 8:  [[fallthrough]]
		case 9:  [[fallthrough]]
		case 10: [[fallthrough]]
		case 11: [[fallthrough]]
		case 12: [[fallthrough]]
		case 13: [[fallthrough]]
		case 14: [[fallthrough]]
		case 15:
			if (*(volatile uint32_t*) BRAMAddrVCAddOffset(node, 0, VCTRIE_ENTRY_FIELD_LC))
			break;
		case 1:
			break;
		case 2: [[fallthrough]]
		case 3:
			break;
		case 4:
			break;
		case 5:
			break;
	}
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
