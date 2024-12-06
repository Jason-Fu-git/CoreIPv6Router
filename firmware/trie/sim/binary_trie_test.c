#include <stdio.h>
#include <time.h>
#include <stdlib.h>

#ifndef _BINARY_TRIE_C_
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

#define CONSTRUCT_BRAM_ENTRY(valid, next_hop_addr, rc, lc) ((valid << 31) | (next_hop_addr << 26) | (rc << 13) | lc)
#define VALID(entry) ((entry >> 31) & 0x1)
#define NEXT_HOP_ADDR(entry) ((entry >> 26) & 0x1F)
#define RC(entry) ((entry >> 13) & 0x1FFF)
#define LC(entry) (entry & 0x1FFF)

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
#endif

extern unsigned int bram_entires[16][8 * N];
extern int bram_tops[16];
extern int bram_empty_bottoms[16];

extern struct RouteTableEntry
{
    unsigned int prefix[4];
    unsigned int prefix_length;
    unsigned int next_hop;
    unsigned int port;
};

extern void updateBramEmptyBottom(int level);
extern void initBram();
extern int lookup(unsigned int prefix[4], int prefix_length, int *current_prefix_length);
extern int insert(unsigned int prefix[4], int prefix_length, unsigned int next_hop_addr);
extern int delete(unsigned int prefix[4], int prefix_length);

// ============================
// Utility functions
// Note : The functions below are not used in the design
// ============================

struct RouteTableEntry generateRandomEntry()
{
    struct RouteTableEntry entry;
    for (int i = 0; i < 4; i++)
    {
        unsigned int prefix = 0;
        for (int j = 0; j < 32; j++)
        {
            prefix |= (rand() % 2) << j;
        }
        entry.prefix[i] = prefix;
    }
    entry.prefix_length = rand() % 128 + 1;
    entry.next_hop = rand() % 31 + 1;
    entry.port = rand() % 4;
    return entry;
}

void printEntry(struct RouteTableEntry entry)
{
    printf("Prefix: %08X%08X%08X%08X ", entry.prefix[0], entry.prefix[1], entry.prefix[2], entry.prefix[3]);
    printf("Prefix length: %d ", entry.prefix_length);
    printf("Next hop: %d ", entry.next_hop);
    printf("Port: %d\n", entry.port);
}

/**
 * Test the initial construction and write of the binary trie
 *
 */
int unitTestInitWrite(int n)
{
    if (n < 0 || n > N)
    {
        printf("Invalid number of entries\n");
        return 1;
    }
    initBram();
    struct RouteTableEntry entries[N];
    // insert N random entries
    for (int i = 0; i < n; i++)
    {
        int has_collision = 0;
        do
        {
            entries[i] = generateRandomEntry();
            int current_prefix_length = 0;
            int address = lookup(entries[i].prefix, entries[i].prefix_length, &current_prefix_length);
            int valid = VALID(bram_entires[LEVEL(address)][INDEX(address)]);
            if (valid)
            {
                has_collision = 1;
                printf("Collision detected for entry %d\n", i);
            }
            else
            {
                int code = insert(entries[i].prefix, entries[i].prefix_length, entries[i].next_hop);
                if (code != 0)
                {
                    printf("Failed to insert entry %d: code %d\n", i, code);
                    exit(code);
                }
                has_collision = 0;
            }
        } while (has_collision);

        {
            // look up the entry
            int current_prefix_length = 0;
            int address = lookup(entries[i].prefix, entries[i].prefix_length, &current_prefix_length);
            if (current_prefix_length != entries[i].prefix_length)
            {
                printf("Failed to lookup entry %d: prefix length got %d, expected %d\n", i, current_prefix_length, entries[i].prefix_length);
                return 1;
            }
            else
            {
                int valid = VALID(bram_entires[LEVEL(address)][INDEX(address)]);
                if (!valid)
                {
                    printf("Failed to lookup entry %d: not valid\n", i);
                    return 1;
                }
                else
                {
                    int next_hop_addr = NEXT_HOP_ADDR(bram_entires[LEVEL(address)][INDEX(address)]);
                    if (next_hop_addr != entries[i].next_hop)
                    {
                        printf("Failed to lookup entry %d: next hop got %d, expected %d\n", i, next_hop_addr, entries[i].next_hop);
                        return 1;
                    }
                }
            }
        }

        printf("Inserted entry %d ", i);
        printEntry(entries[i]);
    }
    // print bram occupation
    for (int i = 0; i < 16; i++)
    {
        printf("Bram %d has %d entries\n", i, bram_tops[i]);
    }
    // lookup the entries
    for (int i = 0; i < n; i++)
    {
        int current_prefix_length = 0;
        int address = lookup(entries[i].prefix, entries[i].prefix_length, &current_prefix_length);
        if (current_prefix_length != entries[i].prefix_length)
        {
            printf("Failed to lookup entry %d: prefix length got %d, expected %d\n", i, current_prefix_length, entries[i].prefix_length);
            return 2;
        }
        else
        {
            int valid = VALID(bram_entires[LEVEL(address)][INDEX(address)]);
            if (!valid)
            {
                printf("Failed to lookup entry %d: not valid\n", i);
                return 3;
            }
            else
            {
                int next_hop_addr = NEXT_HOP_ADDR(bram_entires[LEVEL(address)][INDEX(address)]);
                if (next_hop_addr != entries[i].next_hop)
                {
                    printf("Failed to lookup entry %d: next hop got %d, expected %d\n", i, next_hop_addr, entries[i].next_hop);
                    return 4;
                }
            }
        }
    }
    return 0;
}

/**
 * Test the delete and insert operations
 * @param n max number of iterations
 */
int unitTestDeleteAndInsert(int n)
{
    initBram();
    // route table
    struct RouteTableEntry entries[10 * N];
    int entries_valid[10 * N];
    int top = 0;
    // valid entries
    int valid_num = 0;
    // randomly insert / delete
    for (int i = 0; i < n; i++)
    {
        if (valid_num == N - 1)
        {
            printf("BRAM has reached its highest capacity\n");
            break;
        }
        int is_delete = rand() % 3;
        // delete an entry
        if (is_delete)
        {
            if (top == 0)
            {
                continue;
            }
            int index = rand() % top;
            if (entries_valid[index] == 0)
            {
                continue;
            }
            int code = delete (entries[index].prefix, entries[index].prefix_length);
            if (code != 0)
            {
                printf("Failed to delete entry %d: code %d\n", index, code);
                exit(code);
            }
            entries_valid[index] = 0;
            printf("Deleted entry %d\n", index);
            --valid_num;
        }
        // insert an entry
        else
        {
            int has_collision = 0;
            do
            {
                entries[top] = generateRandomEntry();
                int current_prefix_length = 0;
                int address = lookup(entries[top].prefix, entries[top].prefix_length, &current_prefix_length);
                int valid = VALID(bram_entires[LEVEL(address)][INDEX(address)]);
                if (valid)
                {
                    has_collision = 1;
                    printf("Collision detected for entry %d\n", top);
                }
                else
                {
                    int code = insert(entries[top].prefix, entries[top].prefix_length, entries[top].next_hop);
                    if (code != 0)
                    {
                        printf("Failed to insert entry %d: code %d\n", top, code);
                        exit(code);
                    }
                    has_collision = 0;
                }
            } while (has_collision);

            // print information
            entries_valid[top] = 1;
            printf("Inserted entry %d ", top);
            printEntry(entries[top]);
            top++;
            valid_num++;

            // directly look up the entry
            int current_prefix_length = 0;
            int address = lookup(entries[top - 1].prefix, entries[top - 1].prefix_length, &current_prefix_length);
            if (current_prefix_length != entries[top - 1].prefix_length)
            {
                printf("Failed to lookup entry %d: prefix length got %d, expected %d\n", top - 1, current_prefix_length, entries[top - 1].prefix_length);
                return 1;
            }
            else
            {
                int valid = VALID(bram_entires[LEVEL(address)][INDEX(address)]);
                if (!valid)
                {
                    printf("Failed to lookup entry %d: not valid\n", top - 1);
                    return 1;
                }
                else
                {
                    int next_hop_addr = NEXT_HOP_ADDR(bram_entires[LEVEL(address)][INDEX(address)]);
                    if (next_hop_addr != entries[top - 1].next_hop)
                    {
                        printf("Failed to lookup entry %d: next hop got %d, expected %d\n", top - 1, next_hop_addr, entries[top - 1].next_hop);
                        return 1;
                    }
                }
            }
        }
    }
    // print bram occupation
    for (int i = 0; i < 16; i++)
    {
        printf("Bram %d has %d entries\n", i, bram_tops[i]);
    }
    // look up
    for (int i = 0; i < top; i++)
    {
        if (entries_valid[i] == 0)
        {
            continue;
        }

        int current_prefix_length = 0;
        int address = lookup(entries[i].prefix, entries[i].prefix_length, &current_prefix_length);
        if (current_prefix_length != entries[i].prefix_length)
        {
            printf("Failed to lookup entry %d: prefix length got %d, expected %d\n", i, current_prefix_length, entries[i].prefix_length);
            return 1;
        }
        else
        {
            int valid = VALID(bram_entires[LEVEL(address)][INDEX(address)]);
            if (!valid)
            {
                printf("Failed to lookup entry %d: not valid\n", i);
                return 1;
            }
            else
            {
                int next_hop_addr = NEXT_HOP_ADDR(bram_entires[LEVEL(address)][INDEX(address)]);
                if (next_hop_addr != entries[i].next_hop)
                {
                    printf("Failed to lookup entry %d: next hop got %d, expected %d\n", i, next_hop_addr, entries[i].next_hop);
                    return 1;
                }
            }
        }
    }
    return 0;
}

int main()
{
    srand(time(NULL));
    for (int i = 0; i < 100; i++)
    {
        if (unitTestInitWrite(N - 1))
        {
            printf("Failed to initialize and write the binary trie\n");
            return 1;
        }
        if (unitTestDeleteAndInsert(N * 10) != 0)
        {
            printf("Failed to delete and insert the binary trie\n");
            return 1;
        }
    }
    return 0;
}