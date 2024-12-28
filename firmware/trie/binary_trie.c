/**
 * @file binary_trie.c
 * @brief A binary trie implementation for IPv6 routing table
 * @note The binary trie is implemented as a BRAM with 16 levels, each level has 8 * N entries
 * @author Jason Fu
 *
 */

#include <packet.h>

// ! Should not surpass 1024 !
#define N 256
// From SV
// typedef struct packed {
//   logic [ 3:0] p;      // 4
//   logic        valid;  // 1 whether the next_hop_addr is valid
//   logic [ 4:0] next_hop_addr; //5
//   logic [12:0] rc; // 13
//   logic [12:0] lc; // 13
// } binary_trie_node_t; // 12'd0 is considered the null node

static const void* BRAM_BASE = (void*)0x20000000;

#define CONSTRUCT_BRAM_ENTRY(valid, next_hop_addr, rc, lc) ((valid << 31) | (next_hop_addr << 26) | (rc << 13) | lc)
#define VALID(entry) ((entry >> 31) & 0x1)
#define NEXT_HOP_ADDR(entry) ((entry >> 26) & 0x1F)
#define LC(entry) (entry & 0x1FFF)
#define RC(entry) ((entry >> 13) & 0x1FFF)

// For C code
// typedef struct packed {
//   logic [ 3:0] level;
//   logic [12:0] index;
// } bram_address_t;
#define CONSTRUCT_BRAM_ADDRESS(level, index) (BRAM_BASE | (level << 23) | (index << 10))
#define LEVEL(address) ((address >> 23) & 0xF)
#define INDEX(address) ((address >> 10) & 0x1FFF)

// ip6_4 is an unsigned int array with 4 elements
#define LSB(ip6_4, index) (((ip6_4[(index >> 5) & 0x3]) >> (index & 0x1F)) & 0x1)

static const unsigned int INDEX_BASE = 306496;

unsigned int BTrieAddressToIndex(void* address) {
	return (LEVEL(address) << 11) + INDEX(address) + INDEX_BASE;
}

int bram_tops[16];
int bram_empty_bottoms[16]; // lowest index of empty entry

// update the lowest empty index of the BRAM
void BTrieUpdateBramEmptyBottom(int level) {
    for (int i = bram_empty_bottoms[level]; i < bram_tops[level]; i++) {
        // empty entry
        if (*(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(level, i) == 0) {
            bram_empty_bottoms[level] = i;
            return;
        }
    }
    bram_empty_bottoms[level] = bram_tops[level];
}

/**
 *
 * @brief Lookup the prefix in the binary trie
 * @param prefix the prefix to be looked up
 * @param prefix_length the length of the prefix
 * @param current_prefix_length (will be modified) the length of the prefix that the return address represents
 * @note prefix length should be greater than 0, and leq 128
 * @return if the prefix exists, return its address in the BRAM,
 * otherwise return the address where the prefix should be inserted
 *
 */
int _BTrieLookup(void* prefix_ptr, int prefix_length, int *current_prefix_length) {
    struct ip6_addr prefix = *(struct ip6_addr*)prefix_ptr;
	int address = 0;
    if (prefix_length > 0 && prefix_length <= 128) {
        for (int i = 0; i < prefix_length; i++) {
            int lsb = LSB(prefix, i);
            int level = (i >> 3) & 0xF;

            // extract the entry
            int entry_level = LEVEL(address);
            int entry_index = INDEX(address);
            unsigned int entry = *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(entry_level, entry_index);

            unsigned int lc = LC(entry);
            unsigned int rc = RC(entry);

            if (lsb == 0) {
                // turn left
                if (i == 0) {
                    address = CONSTRUCT_BRAM_ADDRESS(0, 1);
                } else {
                    if (lc == 0) {
                        break;
                    } else {
                        address = CONSTRUCT_BRAM_ADDRESS(level, lc);
                    }
                }
            } else {
                // turn right
                if (i == 0) {
                    address = CONSTRUCT_BRAM_ADDRESS(0, 2);
                } else {
                    if (rc == 0) {
                        break;
                    } else {
                        address = CONSTRUCT_BRAM_ADDRESS(level, rc);
                    }
                }
            }
            *current_prefix_length = i + 1;
        }
    }
    return address;
}

/**
 *
 * @brief Insert a prefix into the binary trie
 * @return 0 - success, 1 - invalid prefix length, 2 - out of memory
 *
 */
int BTrieInsert(void* prefix_ptr, int prefix_length, unsigned int next_hop_addr) {
    struct ip6_addr prefix = *(struct ip6_addr*)prefix_ptr;
	int current_prefix_length = 0;
    int address = _BTrieLookup(prefix_ptr, prefix_length, &current_prefix_length);
    int address_to_write = address;
    if (current_prefix_length < prefix_length) {
        // the prefix does not exist
        for (int i = current_prefix_length; i < prefix_length; i++) {
            int lsb = LSB(prefix, i);
            int level = (i >> 3) & 0xF;

            // extract the entry
            int entry_level = LEVEL(address_to_write);
            int entry_index = INDEX(address_to_write);
            unsigned int entry = *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(entry_level, entry_index);
            unsigned int valid = VALID(entry);
            unsigned int entry_next_hop_addr = NEXT_HOP_ADDR(entry);
            unsigned int lc = LC(entry);
            unsigned int rc = RC(entry);

            // construct a new entry
            int new_index = bram_empty_bottoms[level];
            bram_empty_bottoms[level] += 1;

            // update top pointer
            if (new_index == bram_tops[level]) {
                bram_tops[level] += 1;
            }

            // update the lowest empty index
            BTrieUpdateBramEmptyBottom(level);

            // check if the BRAM is full
            if (bram_tops[level] >= 8 * N) {
                return -2;
            }

            // Construct a new entry (should not be 0)
	        *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(level, new_index) = CONSTRUCT_BRAM_ENTRY(0, 1, 0, 0);
            address_to_write = CONSTRUCT_BRAM_ADDRESS(level, new_index);

            if (lsb == 0) {
                // turn left
	            *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(entry_level, entry_index) = CONSTRUCT_BRAM_ENTRY(valid, entry_next_hop_addr, rc, new_index);
            } else {
                // turn right
	            *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(entry_level, entry_index) = CONSTRUCT_BRAM_ENTRY(valid, entry_next_hop_addr, new_index, lc);
            }
        }
    }

    // write the entry
    {
        // the prefix already exists
        int entry_level = LEVEL(address_to_write);
        int entry_index = INDEX(address_to_write);

        // extract the entry
        unsigned int entry = *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(entry_level, entry_index);
        unsigned int lc = LC(entry);
        unsigned int rc = RC(entry);

        // update the entry
	    *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(entry_level, entry_index) = CONSTRUCT_BRAM_ENTRY(1, next_hop_addr, rc, lc);
    }

    return BTrieAddressToIndex(CONSTRUCT_BRAM_ADDRESS(entry_level, entry_index));
}

/**
 * @brief Delete a prefix from the binary trie
 * @return 0 - success, 1 - invalid prefix length, 2 - prefix not found, 3 - unexpected error
 *
 */
int BTrieDelete(void* prefix_ptr, int prefix_length) {
    // lookup the prefix
	struct ip6_addr prefix = *(struct ip6_addr*)prefix_ptr;
    int current_prefix_length = 0;
    int address = lookup(prefix, prefix_length, &current_prefix_length);

    // the prefix exists
    int entry_level = LEVEL(address);
    int entry_index = INDEX(address);

    // extract the entry
    unsigned int entry = *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(entry_level, entry_index);
    unsigned int lc = LC(entry);
    unsigned int rc = RC(entry);

    if (current_prefix_length != prefix_length) {
        return -2;
    }

    // update the entry
	*(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(entry_level, entry_index) = CONSTRUCT_BRAM_ENTRY(0, 0, rc, lc);

    // leaf node
    if (lc == 0 && rc == 0) {
        // update the bram bottom pointer
        if (entry_index < bram_empty_bottoms[entry_level]) {
            // entry point should not be pointed to
            if (!(entry_level == 0 && (entry_index == 1 || entry_index == 2))) {
                bram_empty_bottoms[entry_level] = entry_index;
            }
        }

        // lookup the node's parent
        if (prefix_length == 1) {
            return BTrieAddressToIndex(address);
        }

        // iteratively delete the parent node
        int should_stop = 0;
        int prev_prefix_length = prefix_length;
        int prev_index = entry_index;
        while (!should_stop) {
            prev_prefix_length--;

            int parent_current_prefix_length = 0;
            int parent_address = lookup(prefix, prev_prefix_length, &parent_current_prefix_length);
            int parent_level = LEVEL(parent_address);
            int parent_index = INDEX(parent_address);
            if (parent_current_prefix_length != prev_prefix_length) {
                return -3;
            }

            // extract the parent entry
            unsigned int parent_entry = *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(parent_level, parent_index);
            unsigned int parent_valid = VALID(parent_entry);
            unsigned int parent_next_hop_addr = parent_valid ? NEXT_HOP_ADDR(parent_entry) : 0;
            unsigned int parent_lc = LC(parent_entry);
            unsigned int parent_rc = RC(parent_entry);

            // check the entry's LSB
            int lsb = LSB(prefix, prev_prefix_length);
            if (lsb == 0) {
                // lc
                if (parent_lc == prev_index) {
	                *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(parent_level, parent_index) = CONSTRUCT_BRAM_ENTRY(parent_valid, parent_next_hop_addr, parent_rc, 0);
                } else {
                    return -3;
                }
            } else {
                // rc
                if (parent_rc == prev_index) {
	                *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(parent_level, parent_index) = CONSTRUCT_BRAM_ENTRY(parent_valid, parent_next_hop_addr, 0, parent_lc);
                } else {
                    return -3;
                }
            }

            // check whether the node is entry point
            if (parent_level == 0 && (parent_index == 1 || parent_index == 2)) {
                should_stop = 1;
            } else {
                // check whether the parent node is now a leaf node
                parent_entry = *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(parent_level, parent_index);
                parent_lc = LC(parent_entry);
                parent_rc = RC(parent_entry);
                if (parent_valid == 0 && parent_lc == 0 && parent_rc == 0) {
                    prev_index = parent_index;
                    // update the bram bottom pointer
                    if (parent_index < bram_empty_bottoms[parent_level]) {
                        bram_empty_bottoms[parent_level] = parent_index;
                    }
                } else {
                    should_stop = 1;
                }
            }
        }
    }
    return BTrieAddressToIndex(address);
}

void BTrieInitBram() {
    for (int i = 0; i < 16; i++) {
	    *(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(i, 0) = 0;
        bram_tops[i] = 1;
        bram_empty_bottoms[i] = 1;
    }
    // initialize the enter points
	*(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(0, 1) = CONSTRUCT_BRAM_ENTRY(0, 0, 0, 0);
	*(volatile unsigned int*)CONSTRUCT_BRAM_ADDRESS(0, 2) = CONSTRUCT_BRAM_ENTRY(0, 0, 0, 0);
    bram_tops[0] = 3;
    bram_empty_bottoms[0] = 3;
}

// Binary Trie functions
void BTrieUpdateBramEmptyBottom(int level);
void BTrieInitBram();
unsigned int BTrieLookup(void* prefix, int prefix_length) {
	int temp;
	return BTrieAddressToIndex(_BTrieLookup(prefix, prefix_length, temp));
}
int BTrieInsert(void* prefix, int prefix_length, unsigned int next_hop_addr);
int BTrieDelete(void* prefix, int prefix_length);
