/**
 * @file binary_trie.c
 * @brief A binary trie implementation for IPv6 routing table
 * @note The binary trie is implemented as a BRAM with 16 levels, each level has 8 * N entries
 * @author Jason Fu
 *
 */
#define _BINARY_TRIE_C_
// ! Should not surpass 1024 !
#define N 256
// From SV
// typedef struct packed {
//   logic [ 3:0] p;      // 4
//   logic        valid;  // 1 whether the next_hop_addr is valid
//   logic [ 4:0] next_hop_addr; //5
//   logic [12:0] lc; // 13
//   logic [12:0] rc; // 13
// } binary_trie_node_t; // 12'd0 is considered the null node

#define CONSTRUCT_BRAM_ENTRY(valid, next_hop_addr, lc, rc) ((valid << 31) | (next_hop_addr << 26) | (lc << 13) | rc)
#define VALID(entry) ((entry >> 31) & 0x1)
#define NEXT_HOP_ADDR(entry) ((entry >> 26) & 0x1F)
#define LC(entry) ((entry >> 13) & 0x1FFF)
#define RC(entry) (entry & 0x1FFF)

// For C code
// typedef struct packed {
//   logic [ 3:0] level;
//   logic [12:0] index;
// } bram_address_t;
#define CONSTRUCT_BRAM_ADDRESS(level, index) ((level << 13) | index)
#define LEVEL(address) ((address >> 13) & 0xF)
#define INDEX(address) (address & 0x1FFF)

// ip6_4 is an unsigned int array with 4 elements
#define LSB(ip6_4, index) (((ip6_4[(index >> 5) & 0x3]) >> (index & 0x1F)) & 0x1)

// prefix example:
// for ip6 address fe80::1
// prefix should be 1000 .... 0000 0001 0111 1111
struct RouteTableEntry
{
    unsigned int prefix[4];
    unsigned int prefix_length;
    unsigned int next_hop;
    unsigned int port;
};

// 0x0 is reserved
unsigned int bram_entires[16][8 * N];
int bram_tops[16];
int bram_empty_bottoms[16]; // lowest index of empty entry

// Binary Trie functions
void updateBramEmptyBottom(int level);
void initBram();
int lookup(unsigned int prefix[4], int prefix_length, int *current_prefix_length);
int insert(unsigned int prefix[4], int prefix_length, unsigned int next_hop_addr);
int delete(unsigned int prefix[4], int prefix_length);

// update the lowest empty index of the BRAM
void updateBramEmptyBottom(int level)
{
    for (int i = bram_empty_bottoms[level]; i < bram_tops[level]; i++)
    {
        // empty entry
        if (bram_entires[level][i] == 0)
        {
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
int lookup(unsigned int prefix[4], int prefix_length, int *current_prefix_length)
{
    int address = 0;
    if (prefix_length > 0 && prefix_length <= 128)
    {
        for (int i = 0; i < prefix_length; i++)
        {
            int lsb = LSB(prefix, i);
            int level = (i >> 3) & 0xF;

            // extract the entry
            int entry_level = LEVEL(address);
            int entry_index = INDEX(address);
            unsigned int entry = bram_entires[entry_level][entry_index];

            unsigned int lc = LC(entry);
            unsigned int rc = RC(entry);

            if (lsb == 0)
            {
                // turn left
                if (i == 0)
                {
                    address = CONSTRUCT_BRAM_ADDRESS(0, 1);
                }
                else
                {
                    if (lc == 0)
                    {
                        break;
                    }
                    else
                    {
                        address = CONSTRUCT_BRAM_ADDRESS(level, lc);
                    }
                }
            }
            else
            {
                // turn right
                if (i == 0)
                {
                    address = CONSTRUCT_BRAM_ADDRESS(0, 2);
                }
                else
                {
                    if (rc == 0)
                    {
                        break;
                    }
                    else
                    {
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
int insert(unsigned int prefix[4], int prefix_length, unsigned int next_hop_addr)
{
    if (prefix_length == 0 || prefix_length > 128)
    {
        return 1;
    }

    int current_prefix_length = 0;
    int address = lookup(prefix, prefix_length, &current_prefix_length);
    int address_to_write = address;

    if (current_prefix_length < prefix_length)
    {
        // the prefix does not exist
        for (int i = current_prefix_length; i < prefix_length; i++)
        {
            int lsb = LSB(prefix, i);
            int level = (i >> 3) & 0xF;

            // extract the entry
            int entry_level = LEVEL(address_to_write);
            int entry_index = INDEX(address_to_write);
            unsigned int entry = bram_entires[entry_level][entry_index];
            unsigned int valid = VALID(entry);
            unsigned int entry_next_hop_addr = NEXT_HOP_ADDR(entry);
            unsigned int lc = LC(entry);
            unsigned int rc = RC(entry);

            // construct a new entry
            int new_index = bram_empty_bottoms[level];
            bram_empty_bottoms[level] += 1;

            // update top pointer
            if (new_index == bram_tops[level])
            {
                bram_tops[level] += 1;
            }

            // update the lowest empty index
            updateBramEmptyBottom(level);

            // check if the BRAM is full
            if (bram_tops[level] >= 8 * N)
            {
                return 2;
            }

            // Construct a new entry (should not be 0)
            bram_entires[level][new_index] = CONSTRUCT_BRAM_ENTRY(0, 1, 0, 0);
            address_to_write = CONSTRUCT_BRAM_ADDRESS(level, new_index);

            if (lsb == 0)
            {
                // turn left
                bram_entires[entry_level][entry_index] = CONSTRUCT_BRAM_ENTRY(valid, entry_next_hop_addr, new_index, rc);
            }
            else
            {
                // turn right
                bram_entires[entry_level][entry_index] = CONSTRUCT_BRAM_ENTRY(valid, entry_next_hop_addr, lc, new_index);
            }
        }
    }

    // write the entry
    {
        // the prefix already exists
        int entry_level = LEVEL(address_to_write);
        int entry_index = INDEX(address_to_write);

        // extract the entry
        unsigned int entry = bram_entires[entry_level][entry_index];
        unsigned int lc = LC(entry);
        unsigned int rc = RC(entry);

        // update the entry
        bram_entires[entry_level][entry_index] = CONSTRUCT_BRAM_ENTRY(1, next_hop_addr, lc, rc);
    }

    return 0;
}

/**
 * @brief Delete a prefix from the binary trie
 * @return 0 - success, 1 - invalid prefix length, 2 - prefix not found, 3 - unexpected error
 *
 */
int delete(unsigned int prefix[4], int prefix_length)
{
    if (prefix_length == 0 || prefix_length > 128)
    {
        return 1;
    }

    // lookup the prefix
    int current_prefix_length = 0;
    int address = lookup(prefix, prefix_length, &current_prefix_length);

    // the prefix exists
    int entry_level = LEVEL(address);
    int entry_index = INDEX(address);

    // extract the entry
    unsigned int entry = bram_entires[entry_level][entry_index];
    unsigned int valid = VALID(entry);
    unsigned int next_hop_addr = NEXT_HOP_ADDR(entry);
    unsigned int lc = LC(entry);
    unsigned int rc = RC(entry);

    if (current_prefix_length != prefix_length)
    {
        return 2;
    }

    // update the entry
    bram_entires[entry_level][entry_index] = CONSTRUCT_BRAM_ENTRY(0, 0, lc, rc);

    // leaf node
    if (lc == 0 && rc == 0)
    {
        // update the bram bottom pointer
        if (entry_index < bram_empty_bottoms[entry_level])
        {
            // entry point should not be pointed to
            if (!(entry_level == 0 && (entry_index == 1 || entry_index == 2)))
            {
                bram_empty_bottoms[entry_level] = entry_index;
            }
        }

        // lookup the node's parent
        if (prefix_length == 1)
        {
            return 0;
        }

        // iteratively delete the parent node
        int should_stop = 0;
        int prev_prefix_length = prefix_length;
        int prev_index = entry_index;
        while (!should_stop)
        {
            prev_prefix_length--;

            int parent_current_prefix_length = 0;
            int parent_address = lookup(prefix, prev_prefix_length, &parent_current_prefix_length);
            int parent_level = LEVEL(parent_address);
            int parent_index = INDEX(parent_address);
            if (parent_current_prefix_length != prev_prefix_length)
            {
                return 3;
            }

            // extract the parent entry
            unsigned int parent_entry = bram_entires[parent_level][parent_index];
            unsigned int parent_valid = VALID(parent_entry);
            unsigned int parent_next_hop_addr = parent_valid ? NEXT_HOP_ADDR(parent_entry) : 0;
            unsigned int parent_lc = LC(parent_entry);
            unsigned int parent_rc = RC(parent_entry);

            // check the entry's LSB
            int lsb = LSB(prefix, prev_prefix_length);
            if (lsb == 0)
            {
                // lc
                if (parent_lc == prev_index)
                {
                    bram_entires[parent_level][parent_index] = CONSTRUCT_BRAM_ENTRY(parent_valid, parent_next_hop_addr, 0, parent_rc);
                }
                else
                {
                    return 3;
                }
            }
            else
            {
                // rc
                if (parent_rc == prev_index)
                {
                    bram_entires[parent_level][parent_index] = CONSTRUCT_BRAM_ENTRY(parent_valid, parent_next_hop_addr, parent_lc, 0);
                }
                else
                {
                    return 3;
                }
            }

            // check whether the node is entry point
            if (parent_level == 0 && (parent_index == 1 || parent_index == 2))
            {
                should_stop = 1;
            }
            else
            {
                // check whether the parent node is now a leaf node
                parent_entry = bram_entires[parent_level][parent_index];
                parent_lc = LC(parent_entry);
                parent_rc = RC(parent_entry);
                if (parent_valid == 0 && parent_lc == 0 && parent_rc == 0)
                {
                    prev_index = parent_index;
                    // update the bram bottom pointer
                    if (parent_index < bram_empty_bottoms[parent_level])
                    {
                        bram_empty_bottoms[parent_level] = parent_index;
                    }
                }
                else
                {
                    should_stop = 1;
                }
            }
        }
    }
    return 0;
}

void initBram()
{
    for (int i = 0; i < 16; i++)
    {
        bram_entires[i][0] = 0;
        bram_tops[i] = 1;
        bram_empty_bottoms[i] = 1;
    }
    // initialize the enter points
    bram_entires[0][1] = CONSTRUCT_BRAM_ENTRY(0, 0, 0, 0);
    bram_entires[0][2] = CONSTRUCT_BRAM_ENTRY(0, 0, 0, 0);
    bram_tops[0] = 3;
    bram_empty_bottoms[0] = 3;
}

// void writeBram(int level, char *filename)
// {
//     FILE *fp = fopen(filename, "w");
//     for (int i = 0; i < bram_tops[level]; i++)
//     {
//         fprintf(fp, "%08X\n", bram_entires[level][i]);
//     }
//     fclose(fp);
// }

// int main()
// {
//     initBram();
//     struct RouteTableEntry entry1;
//     // 31AB3AF19AB3F4CF809B322C7F8F6812
//     entry1.prefix[0] = 0x7F8F6812;
//     entry1.prefix[1] = 0x09B322C7;
//     entry1.prefix[2] = 0x9AB3F4CF;
//     entry1.prefix[3] = 0x31AB3AF1;
//     entry1.prefix_length = 2;
//     entry1.next_hop = 13;
//     entry1.port = 3;
//     insert(entry1.prefix, entry1.prefix_length, entry1.next_hop);

//     struct RouteTableEntry entry2;
//     // 9B71927BD3CCB032A2043FDA7340CD12
//     entry2.prefix[0] = 0x7340CD12;
//     entry2.prefix[1] = 0xA2043FDA;
//     entry2.prefix[2] = 0xD3CCB032;
//     entry2.prefix[3] = 0x9B71927B;
//     entry2.prefix_length = 17;
//     entry2.next_hop = 18;
//     entry2.port = 2;
//     insert(entry2.prefix, entry2.prefix_length, entry2.next_hop);

//     delete (entry2.prefix, entry2.prefix_length);

//     // write
//     for (int i = 0; i < 16; i++)
//     {
//         char filename[100];
//         sprintf(filename, "bram_%d.txt", i);
//         writeBram(i, filename);
//     }
// }