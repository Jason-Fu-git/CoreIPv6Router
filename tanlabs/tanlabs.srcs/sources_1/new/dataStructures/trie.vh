localparam ENTRY_SIZE = 38;

typedef struct packed {
  logic [ 4:0] entry_offset;
  logic [27:0] prefix;
  logic [ 4:0] prefix_length;
} Entry;

typedef struct packed {
  logic [ENTRY_SIZE-1:0] bin;
  logic [7:0] rc;
  logic [7:0] lc;
} Node1;

typedef struct packed {
  logic [15*ENTRY_SIZE-1:0] bin;
  logic [7:0] rc;
  logic [7:0] lc;
} Node15Addr8;

typedef struct packed {
  logic [15*ENTRY_SIZE-1:0] bin;
  logic [13:0] rc;
  logic [13:0] lc;
} Node15Addr14;

typedef struct packed {
  logic [11*ENTRY_SIZE-1:0] bin;
  logic [13:0] rc;
  logic [13:0] lc;
} Node11;

typedef struct packed {
  logic [5*ENTRY_SIZE-1:0] bin;
  logic [12:0] rc;
  logic [12:0] lc;
} Node5;

typedef struct packed {
  logic [ 3:0] p;      // 4
  logic        valid;  // 1 Note : 12'd0.valid should be 0
  logic [ 4:0] next_hop_addr; //5
  logic [12:0] rc; // 13
  logic [12:0] lc; // 13
} binary_trie_node_t; // 12'd0 is considered the null node

typedef Node1        NL0;
typedef Node15Addr8  NL1;
typedef Node15Addr14 NL2;
typedef Node15Addr14 NL3;
typedef Node15Addr14 NL4;
typedef Node11       NL5;
typedef Node5        NL6;
typedef Node5        NL7;
typedef Node5        NL8;
typedef Node5        NL9;
typedef Node5        NL10;
typedef Node5        NL11;
typedef Node5        NL12;
typedef Node5        NL13;
typedef Node5        NL14;
typedef Node5        NL15;

