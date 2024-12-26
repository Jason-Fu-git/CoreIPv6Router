//
// Created by Yusaki on 24-12-24.
//

#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <fstream>

typedef unsigned int uint32_t;

const uint32_t BRAM_BASE = 0x20800000;

const uint32_t MAX_PREFIX_LEN = 28;

uint32_t htonl(uint32_t x) {
	return ((x & 0xff) << 24)
	| ((x & 0xff00) << 8)
	| ((x & 0xff0000) >> 8)
	| ((x & 0xff000000) >> 24);
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
		converted[0] = htonl(ip[0]);
		converted[1] = htonl(ip[1]);
		converted[2] = htonl(ip[2]);
		converted[3] = htonl(ip[3]);
		sprintf(buffer, "%08x%08x%08x%08x", converted[0], converted[1], converted[2], converted[3]);
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
		(lsb ? rc: lc) = child;
	}
	bool noChild(uint32_t lsb) {
		return (lsb ? rc: lc) == 0;
	}
	VCEntry* getBin() {
		return bin;
	}
	uint32_t match(uint32_t prefix, uint32_t length, uint32_t bin_size) {
		for (int index = 0; index < bin_size; ++index) {
			if (bin[index].match(prefix, length)) {
				return index;
			}
		}
		return bin_size;
	}
};

typedef VCNode<0>* VCNodePtr;

uint32_t BRAM_DEPTHS[16] = {
		64, 256, 6144, 7168, 5120, 3072, 256, 256,
		256, 256, 256, 256, 256, 256, 256, 256
};

VCNode<1>  BRAM_0[64];
VCNode<7>  BRAM_1[256];
VCNode<15> BRAM_2[6144];
VCNode<15> BRAM_3[7168];
VCNode<14> BRAM_4[5120];
VCNode<10> BRAM_5[3072];
VCNode<1>  BRAM_6[256];
VCNode<1>  BRAM_7[256];
VCNode<1>  BRAM_8[256];
VCNode<1>  BRAM_9[256];
VCNode<1>  BRAM_a[256];
VCNode<1>  BRAM_b[256];
VCNode<1>  BRAM_c[256];
VCNode<1>  BRAM_d[256];
VCNode<1>  BRAM_e[256];
VCNode<1>  BRAM_f[256];

void* BRAM_BASES[16] = {
	BRAM_0, BRAM_1, BRAM_2, BRAM_3, BRAM_4, BRAM_5, BRAM_6, BRAM_7,
	BRAM_8, BRAM_9, BRAM_a, BRAM_b, BRAM_c, BRAM_d, BRAM_e, BRAM_f
};

uint32_t BRAM_SIZES[16] = {
	sizeof(VCNode<1>), sizeof(VCNode<7>), sizeof(VCNode<15>), sizeof(VCNode<15>),
	sizeof(VCNode<14>), sizeof(VCNode<10>), sizeof(VCNode<1>), sizeof(VCNode<1>),
	sizeof(VCNode<1>), sizeof(VCNode<1>), sizeof(VCNode<1>), sizeof(VCNode<1>),
	sizeof(VCNode<1>), sizeof(VCNode<1>), sizeof(VCNode<1>), sizeof(VCNode<1>)
};

uint32_t BIN_SIZES[16] = {
	1, 7, 15, 15, 14, 10, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1
};

class VCTrie {
protected:
	VCNode<1> root;
	uint32_t node_count;
	uint32_t node_num[16];
	uint32_t excessive_count;
	char error_buffer[64];
public:
	VCTrie() : node_count(0), excessive_count(0) {
		for (uint32_t i = 0; i < 16; ++i) {
			node_num[i] = 0;
		}
	}
	VCNodePtr _childAddrInStage(VCNodePtr outer, uint32_t stage, uint32_t lsb) const {
		return (VCNodePtr)((size_t)BRAM_BASES[stage] + (outer->getChild(lsb)) * BRAM_SIZES[stage]);
	}
	uint32_t _create_subtree(VCNodePtr node, uint32_t stage, uint32_t level, uint32_t lsb) {
		if (node->noChild(lsb)) {
			++node_count;
			uint32_t next_stage = (/*level >= 7 ? stage + 1 : */stage);
			++node_num[next_stage];
			if (node_num[next_stage] >= BRAM_DEPTHS[next_stage]) {
				// printf("[WARN] Exceeding BRAM depth\n");
				--node_count;
				--node_num[next_stage];
				return -1;
			}
			// Since every BRAM leaves out address 0x0, the node_num is just the index of the last node.
			node->setChild(lsb, node_num[next_stage]);
			return 1;
		}
		return 0;
	}
	/*
	 * Insert a prefix into the trie.
	 * If the prefix is excessive, return 1.
	 * Else, return 0.
	 * */
	uint32_t insert(const IP6& prefix_raw, uint32_t length, uint32_t next_hop) {
		IP6 prefix = prefix_raw;
		VCNodePtr now = (VCNodePtr)&root;
		uint32_t stage_level = 0;
		uint32_t freeIndex = -1;
#define stage (stage_level >> 3)
#define now_stage ((stage_level == 0) ? (0) : ((stage_level - 1) >> 3))
#define level (stage_level & 0x7)
#define lsb   (prefix & 0x1)
#define _NEXT_LEVEL if(_create_subtree(now, stage, level, lsb) == (uint32_t)-1) { \
                goto END;                                                         \
			} \
            now = _childAddrInStage(now, stage, lsb); \
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
			return 0;
		}
		// excessive
		END:
		prefix_raw.toHex(error_buffer);
		// printf("[WARN] Ex:%s/%d\n", error_buffer, length);
		++excessive_count;
		return 1;  // needs to be handled
#undef stage
#undef now_stage
#undef level
#undef lsb
#undef _NEXT_LEVEL
	}
	/*
	 * Lookup a prefix in the trie.
	 * *Not to lookup max prefix match*
	 * Return the address of the entry if found, else return 0.
	 * */
	size_t lookup_entry(const IP6& prefix_raw, uint32_t length) {
		IP6 prefix = prefix_raw;
		VCNodePtr now = (VCNodePtr)&root;
		uint32_t stage_level = 0;
#define stage (stage_level >> 3)
#define now_stage ((stage_level == 0) ? (0) : ((stage_level - 1) >> 3))
#define level (stage_level & 0x7)
#define lsb   (prefix & 0x1)
		while (length > stage_level + MAX_PREFIX_LEN) {
			if (now->noChild(lsb)) {
				return 0;
			}
			now = _childAddrInStage(now, stage, lsb);
			prefix >>= 1;
			++stage_level;
		}
		while (stage_level <= length) {
			uint32_t match_index = now->match(prefix.ip[0], length - stage_level, BIN_SIZES[now_stage]);
			if (match_index != BIN_SIZES[now_stage]) {
				return (size_t)&(now->getBin()[match_index]);
			}
			if (now->noChild(lsb)) {
				return 0;
			}
			now = _childAddrInStage(now, stage, lsb);
			prefix >>= 1;
			++stage_level;
		}
		return 0;
#undef stage
#undef now_stage
#undef level
#undef lsb
	}
	uint32_t get_node_count() const {
		return node_count;
	}
	uint32_t get_excessive_count() const {
		return excessive_count;
	}
	void print() const {
		for (uint32_t i = 0; i < 16; ++i) {
			printf("Stage %d: %d/%d\n", i, node_num[i], BRAM_DEPTHS[i]);
		}
	}
};

int main() {
	auto fs = std::fstream("../route_for_cpp.txt", std::ios::in);
	srand(time(nullptr));
	// printf("sizeof(VCNode<%d>) = %llu\n", 1, sizeof(VCNode<1>));
	printf("Launching test\n");
	VCTrie trie;
	char buffer[64];
	for (size_t _ = 0; _ < 223424; _++) {
		IP6 prefix, next_hop_ip;
		uint32_t next_hop, length;
		fs >> prefix.ip[0];
		fs >> prefix.ip[1];
		fs >> prefix.ip[2];
		fs >> prefix.ip[3];
		fs >> length;
		fs >> next_hop_ip.ip[0];
		fs >> next_hop_ip.ip[1];
		fs >> next_hop_ip.ip[2];
		fs >> next_hop_ip.ip[3];
		fs >> next_hop;
		prefix.toHex(buffer);
		// printf("Inserting %s/%u:%u\n", buffer, length, next_hop);
		// for (uint32_t i = 0; i < 32; ++i) {
		// 	printf("%d", (prefix.ip[0] >> i) & 1);
		// }
		// puts("");
		uint32_t excessive = trie.insert(prefix, length, next_hop);
		if (excessive) {
			continue;
		}
		size_t result = trie.lookup_entry(prefix, length);
		if (result == 0) {
			printf("Error in iter: %lld\n", _);
			return 1;
		}
		// puts("Right");
	}
	printf("Done\n");
	printf("Node count: %d\n", trie.get_node_count());
	printf("Excessive count: %d\n", trie.get_excessive_count());
	trie.print();
	return 0;
}
