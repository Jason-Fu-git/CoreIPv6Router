//
// Created by Yusaki on 24-12-21.
//

#include <stdio.h>
#include <packet.h>

/*
 * | 31     28 | 27    | 26 23 | 22      10 | 9          0 |
 * | BRAM 0010 | VC/BT | Stage | Node Index | Field Offset |
 * */

static const void* BRAM_BASE = (void*)0x28000000;

static const uint32_t MAX_PREFIX_LEN = 28;

static const uint32_t BRAM_DEPTHS[16] = {
	64, 256, 6144, 7168, 5120, 3072, 256, 256,
	256, 256, 256, 256, 256, 256, 256, 256
};

static const uint32_t BIN_SIZES[16] = {
	1, 7, 15, 15, 14, 10, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1
};

static const uint32_t NODE_SIZE_PREFIX_SUMS[17] = {
	0, 64, 1856, 94016,
	201536, 273216, 303936, 304192,
	304448, 304704, 304960, 305216,
	305472, 305728, 305984, 306240,
	306496
};

extern "C" void* VCTrieIndexToAddress(uint32_t index) {
	uint32_t stage = 0;
	while (index >= NODE_SIZE_PREFIX_SUMS[stage]) {
		++stage;
	}
    --stage;
	uint32_t offset = index - NODE_SIZE_PREFIX_SUMS[stage];
    uint32_t node = offset / BIN_SIZES[stage];
    offset = offset % BIN_SIZES[stage];
	return (void*)((uint32_t)BRAM_BASE | (stage << 23) | (node << 10) | ((offset + 1) << 4));
}

extern "C" uint32_t VCTrieAddressToIndex(void* address) {
	uint32_t stage = ((uint32_t)address >> 23) & 0xF;
	uint32_t node = ((uint32_t)address >> 10) & 0x1FFF;
    uint32_t entry_offset = (((uint32_t)address >> 4) & 0x3F) - 1;
    uint32_t node_offset = 0;
    switch(stage) {
        case 2:
        case 3:
            node_offset = (node << 4) - node; // * 15
            break;
        case 4:
            node_offset = (node << 4) - (node << 1); // * 14
            break;
        case 5:
            node_offset = (node << 3) + (node << 1); // * 10
            break;
        case 1:
            node_offset = (node << 3) - node; // * 7
            break;
        default:
            node_offset = node; // * 1
            break;
    }
	return NODE_SIZE_PREFIX_SUMS[stage] + node_offset + entry_offset;
}

struct IP6 {
	uint32_t ip[4];
	IP6() : ip{0, 0, 0, 0} {}
	IP6& operator= (const IP6& other) {
		ip[0] = other.ip[0];
        ip[1] = other.ip[1];
        ip[2] = other.ip[2];
        ip[3] = other.ip[3];
        return *this;
    }
	IP6& operator>>= (const uint32_t shift) {
		ip[0] >>= shift;
		ip[0] |= (ip[1] << (32 - shift));
		ip[1] >>= shift;
		ip[1] |= (ip[2] << (32 - shift));
		ip[2] >>= shift;
		ip[2] |= (ip[3] << (32 - shift));
		ip[3] >>= shift;
		return *this;
	}
	uint32_t operator& (const uint32_t mask) const {
		return ip[0] & mask;
	}
	void toHex(char* buffer) const {
		uint32_t converted[4];
		converted[0] = brev8(htonl(ip[0]));
		converted[1] = brev8(htonl(ip[1]));
		converted[2] = brev8(htonl(ip[2]));
		converted[3] = brev8(htonl(ip[3]));
		sprintf(buffer, "%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x",
	        converted[0] >> 16, converted[0] & 0xffff,
	        converted[1] >> 16, converted[1] & 0xffff,
	        converted[2] >> 16, converted[2] & 0xffff,
	        converted[3] >> 16, converted[3] & 0xffff
		);
	}
};

/*
 * There are 16 stages in the trie, each consisting of 8 levels.
 * The root of the trie is out of the BRAM.
 * Thus, each stage, we have an outer node.
 * The outer node has left and right children pointing to the inner nodes of the next stage.
 * *An address transformation should be done here*
*/

struct VCEntry {
	uint32_t length;  // prefix length, 0~28, using 31 (5'b11111) to mark as invalid
	uint32_t prefix;  // prefix, 0~28 bits in lower part
	uint32_t next_hop;  // index of next hop table, 0~30, using 31 (5'b11111) to mark as invalid
	uint32_t padding;
	VCEntry() : length(31), prefix(0), next_hop(31) {}
	bool isValid() const {
		return (length < 31) && (next_hop < 31);
	}
	bool isInvalid() const {
		return (length >= 31) || (next_hop >= 31);
	}
	bool match(uint32_t _prefix, uint32_t _length) const {
		return (prefix == _prefix) && (length == _length);
	}
	void invalidate() {
		length = 31;
		next_hop = 31;
	}
};

template <uint32_t BIN_SIZE>
class VCNode {
protected:
	// lc & rc are the index of left child and right child in the BRAM, 0 is always empty, not allowed to read/write
	uint32_t lc;
	uint32_t rc;
	uint32_t padding0;
	uint32_t padding1;
	VCEntry bin[BIN_SIZE];
public:
	VCNode() : lc(0), rc(0) {}
	uint32_t isAvailable(uint32_t bin_size) const {
		for (uint32_t index = 0; index < bin_size; ++index) {
			if (bin[index].isInvalid()) {
				return index;
			}
		}
		return bin_size; // full
	}
	uint32_t getLc() const {
		return lc;
	}
	uint32_t getRc() const {
		return rc;
	}
	uint32_t getChild(uint32_t lsb) const {
		return lsb ? rc : lc;
	}
	void setLc(uint32_t _lc) {
		lc = _lc;
	}
	void setRc(uint32_t _rc) {
		rc = _rc;
	}
	void setChild(uint32_t lsb, uint32_t child) {
		if (lsb) {
			rc = child;
		} else {
			lc = child;
		}
	}
	bool noChild(uint32_t lsb) const {
		return ((lsb == 1) ? rc == 0: lc == 0);
	}
	VCEntry* getBin() {
		return bin;
	}
	uint32_t match(uint32_t prefix, uint32_t length, uint32_t bin_size) const {
		for (uint32_t index = 0; index < bin_size; ++index) {
			if (bin[index].match(prefix, length)) {
				return index;
			}
		}
		return bin_size;
	}
};

typedef VCNode<0>* VCNodePtr;

class VCTrie {
protected:
	VCNode<1> root;
	uint32_t node_count;
	uint32_t node_num[16];
	uint32_t excessive_count;
	char error_buffer[64];
public:
	VCTrie() : node_count(0), excessive_count(0) {}
	VCTrie(const VCTrie&) = delete;
	VCNodePtr _childAddrInStage(VCNodePtr outer, uint32_t stage, uint32_t lsb) const {
		return (VCNodePtr)((uint32_t)BRAM_BASE | (stage << 23) | (outer->getChild(lsb) << 10));
	}
	uint32_t _create_subtree(VCNodePtr node, uint32_t stage, uint32_t lsb) {
		if (node->noChild(lsb)) {
			++node_count;
			++node_num[stage];
			if (node_num[stage] >= BRAM_DEPTHS[stage]) {
				printf("[TC]E");
                _putchar('\0');
				--node_count;
				--node_num[stage];
				return -1;
			}
			// Since every BRAM leaves out address 0x0, the node_num is just the index of the last node.
			node->setChild(lsb, node_num[stage]);
			return 1;
		}
		return 0;
	}
	/*
	 * Insert a prefix into the trie.
	 * If the prefix is excessive, return 1.
	 * Else, return 0.
	 * */
	uint32_t insert(IP6* prefix_raw, uint32_t length, uint32_t next_hop) {
		IP6 prefix = *prefix_raw;
		VCNodePtr now = (VCNodePtr)(&root);
		uint32_t stage_level = 0;
		uint32_t freeIndex = -1;
#define stage (stage_level >> 3)
#define now_stage ((stage_level == 0) ? (0) : ((stage_level - 1) >> 3))
#define level (stage_level & 0x7)
#define lsb   (prefix & 0x1)
#define _NEXT_LEVEL \
			if (_create_subtree(now, stage, lsb) == (uint32_t)-1) { \
				goto END;                                \
			}                                            \
            now = _childAddrInStage(now, stage, lsb);    \
            prefix >>= 1; ++stage_level

		while (length > stage_level + MAX_PREFIX_LEN) {
			_NEXT_LEVEL;
		}
		while (stage_level <= length) {
			freeIndex = now->isAvailable(BIN_SIZES[now_stage]);
			if (freeIndex != BIN_SIZES[now_stage]) {  // available
				break;
			}
			_NEXT_LEVEL;
		}
		if (stage_level <= length) {  // found a place
			VCEntry* bin = now->getBin();
			bin[freeIndex].length = length - stage_level;
			bin[freeIndex].prefix = prefix.ip[0];
			bin[freeIndex].next_hop = next_hop;
			return VCTrieAddressToIndex(&now->getBin()[freeIndex]);
		}
END: // excessive
		prefix_raw->toHex(error_buffer);
		// printf("E%s/%d", error_buffer, length);
        _putchar('\0');
		++excessive_count;
		return 0xffffffff;
#undef stage
#undef now_stage
#undef level
#undef lsb
#undef _NEXT_LEVEL
	}
	/*
	 * Lookup a prefix in the trie.
	 * *Not to lookup max prefix match*
	 * Return the index of the entry if found, else return -1.
	 * */
	uint32_t lookup_entry(IP6* prefix_raw, uint32_t length) {
		IP6 prefix = *prefix_raw;
		VCNodePtr now = (VCNodePtr)(&root);
		uint32_t stage_level = 0;
#define stage (stage_level >> 3)
#define now_stage ((stage_level == 0) ? (0) : ((stage_level - 1) >> 3))
#define level (stage_level & 0x7)
#define lsb   (prefix & 0x1)
		while (length > stage_level + MAX_PREFIX_LEN) {
			if (now->noChild(lsb)) {
				return 0xffffffff;
			}
			now = _childAddrInStage(now, stage, lsb);
			prefix >>= 1;
			++stage_level;
		}
		while (stage_level <= length) {
			uint32_t match_index = now->match(prefix.ip[0], length - stage_level, BIN_SIZES[now_stage]);
			if (match_index != BIN_SIZES[now_stage]) {
				return VCTrieAddressToIndex(&(now->getBin()[match_index]));
			}
			if (now->noChild(lsb)) {
				return 0xffffffff;
			}
			now = _childAddrInStage(now, stage, lsb);
			prefix >>= 1;
			++stage_level;
		}
		return 0xffffffff;
#undef stage
#undef now_stage
#undef level
#undef lsb
	}
    VCNodePtr get_root() {
        return (VCNodePtr)&root;
    }
	uint32_t get_node_count() const {
		return node_count;
	}
	uint32_t get_excessive_count() const {
		return excessive_count;
	}
    uint32_t& get_node_count() {
		return node_count;
    }
    uint32_t& get_excessive_count() {
		return excessive_count;
    }
    uint32_t* get_node_num() {
        return node_num;
    }
};

VCTrie trie __attribute__((section(".data")));

extern "C" void VCTrieInit() {
    trie.get_node_count() = 0;
    trie.get_excessive_count() = 0;
    trie.get_node_num()[0] = 2;
    trie.get_root()->setLc(1);
    trie.get_root()->setRc(2);
	for (uint32_t stage = 1; stage < 16; ++stage) {
		trie.get_node_num()[stage] = 0;
    //     for (uint32_t index = 0; index < BRAM_DEPTHS[stage]; ++index) {
    //         VCNodePtr base = (VCNodePtr)((uint32_t)BRAM_BASE | (stage << 23) | (index << 10));
    //         base->setLc(0);
    //         base->setRc(0);
    //         VCEntry* bin = base->getBin();
    //         for (uint32_t i = 0; i < BIN_SIZES[stage]; ++i) {
    //             bin[i].invalidate();
    //         }
    //     }
    }
}

extern "C" uint32_t VCTrieInsert(void* prefix, uint32_t length, uint32_t next_hop) {
	return trie.insert((IP6*)prefix, length, next_hop);
}

extern "C" uint32_t VCTrieLookup(void* prefix, uint32_t length) {
	return trie.lookup_entry((IP6*)prefix, length);
}

extern "C" uint32_t VCTrieGetNodeCount() {
	return trie.get_node_count();
}

extern "C" uint32_t VCTrieGetExcessiveCount() {
	return trie.get_excessive_count();
}

extern "C" uint32_t VCEntryIsValid(void* entry_addr) {
	return ((VCEntry*)entry_addr)->isValid();
}

extern "C" uint32_t VCEntryIsInvalid(void* entry_addr) {
	return ((VCEntry*)entry_addr)->isInvalid();
}

extern "C" void VCEntryInvalidate(void* entry_addr) {
	((VCEntry*)entry_addr)->invalidate();
}
