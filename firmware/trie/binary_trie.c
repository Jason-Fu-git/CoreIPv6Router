#include <stdio.h>
// From SV
// typedef struct packed {
//   logic [ 3:0] p;      // 4
//   logic        valid;  // 1 Note : 12'd0.valid should be 0
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
unsigned int bram_entires[16][8 * 1024];
int bram_pointers[16];

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
            int level = (i >> 4) & 0xF;

            // extract the entry
            int entry_level = LEVEL(address);
            int entry_index = INDEX(address);
            unsigned int entry = bram_entires[entry_level][entry_index];

            unsigned int valid = VALID(entry);
            unsigned int next_hop_addr = NEXT_HOP_ADDR(entry);
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
                    if (!valid || lc == 0)
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
                    if (!valid || rc == 0)
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
            int level = (i >> 4) & 0xF;

            // extract the entry
            int entry_level = LEVEL(address_to_write);
            int entry_index = INDEX(address_to_write);
            unsigned int entry = bram_entires[entry_level][entry_index];
            unsigned int valid = VALID(entry);
            unsigned int entry_next_hop_addr = NEXT_HOP_ADDR(entry);
            unsigned int lc = LC(entry);
            unsigned int rc = RC(entry);

            // construct a new entry
            int new_index = bram_pointers[level];
            bram_pointers[level] += 1;
            if (new_index >= 8 * 1024)
            {
                return 2;
            }

            bram_entires[level][new_index] = CONSTRUCT_BRAM_ENTRY(0, 0, 0, 0);
            address_to_write = CONSTRUCT_BRAM_ADDRESS(level, new_index);

            if (lsb == 0)
            {
                // turn left
                bram_entires[entry_level][entry_index] = CONSTRUCT_BRAM_ENTRY(1, entry_next_hop_addr, new_index, rc);
            }
            else
            {
                // turn right
                bram_entires[entry_level][entry_index] = CONSTRUCT_BRAM_ENTRY(1, entry_next_hop_addr, lc, new_index);
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

void init_bram()
{
    for (int i = 0; i < 16; i++)
    {
        bram_entires[i][0] = 0;
        bram_pointers[i] = 1;
    }
    // initialize the enter points
    bram_entires[0][1] = CONSTRUCT_BRAM_ENTRY(0, 0, 0, 0);
    bram_entires[0][2] = CONSTRUCT_BRAM_ENTRY(0, 0, 0, 0);
    bram_pointers[0] = 3;
}

void write_bram(int level, char *filename)
{
    FILE *fp = fopen(filename, "w");
    for (int i = 0; i < bram_pointers[level]; i++)
    {
        fprintf(fp, "%08X\n", bram_entires[level][i]);
    }
    fclose(fp);
}

int main()
{
    init_bram();
    struct RouteTableEntry entry;
    entry.prefix[0] = 0x0000000F;
    entry.prefix[1] = 0x40506070;
    entry.prefix[2] = 0x8090A0B0;
    entry.prefix[3] = 0xC0D0E0F0;
    entry.prefix_length = 4;
    entry.next_hop = 31;
    entry.port = 1;
    int code = insert(entry.prefix, entry.prefix_length, entry.next_hop);
    for (int i = 0; i < 16; i++)
    {
        char filename[20];
        filename[0] = 'b';
        filename[1] = 'r';
        filename[2] = 'a';
        filename[3] = 'm';
        filename[4] = '_';
        filename[5] = i + 'a';
        filename[6] = '.';
        filename[7] = 't';
        filename[8] = 'x';
        filename[9] = 't';
        filename[10] = '\0';
        write_bram(i, filename);
    }
    return code;
}