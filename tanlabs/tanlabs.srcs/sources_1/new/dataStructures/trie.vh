`ifndef TRIE_VH
`define TRIE_VH
localparam ENTRY_SIZE = 38;

typedef struct packed {
  logic [ 4:0] entry_offset;
  logic [27:0] prefix;
  logic [ 4:0] prefix_length;
} Entry;

typedef struct packed {
  Entry bin;
  logic [7:0] rc;
  logic [7:0] lc;
} Node1;

typedef struct packed {
  logic [13:0] padding;
  Entry [ 6:0] bin;
  logic [12:0] rc;
  logic [12:0] lc;
} Node7;

typedef struct packed {
  logic [15:0] padding;
  Entry [14:0] bin;
  logic [12:0] rc;
  logic [12:0] lc;
} Node15;

typedef struct packed {
  Entry [13:0] bin;
  logic [12:0] rc;
  logic [12:0] lc;
} Node14;

typedef struct packed {
  logic [ 9:0] padding;
  Entry [ 9:0] bin;
  logic [11:0] rc;
  logic [11:0] lc;
} Node10;

typedef struct packed {
  logic [31:0] entry_offset;
  logic [31:0] prefix;
  logic [31:0] prefix_length;
} Entry_Aligned; // 96 bits

typedef struct packed {
  Entry_Aligned bin;
  logic [31:0] rc;
  logic [31:0] lc;
} Node1_Aligned; // 160 bits

typedef struct packed {
  Entry_Aligned [6:0] bin;
  logic [31:0] rc;
  logic [31:0] lc;
} Node7_Aligned; // 736 bits

typedef struct packed {
  Entry_Aligned [14:0] bin;
  logic [31:0] rc;
  logic [31:0] lc;
} Node15_Aligned; // 1504 bits

typedef struct packed {
  Entry_Aligned [13:0] bin;
  logic [31:0] rc;
  logic [31:0] lc;
} Node14_Aligned;

typedef struct packed {
  Entry_Aligned [9:0] bin;
  logic [31:0] rc;
  logic [31:0] lc;
} Node10_Aligned;

typedef struct packed {
  logic [ 3:0] p;      // 4
  logic        valid;  // 1 Note : 12'd0.valid should be 0
  logic [ 4:0] next_hop_addr; //5
  logic [12:0] rc; // 13
  logic [12:0] lc; // 13
} binary_trie_node_t; // 12'd0 is considered the null node

// typedef Node1        NL0;
// typedef Node15Addr8  NL1;
// typedef Node15Addr14 NL2;
// typedef Node15Addr14 NL3;
// typedef Node15Addr14 NL4;
// typedef Node11       NL5;
// typedef Node5        NL6;
// typedef Node5        NL7;
// typedef Node5        NL8;
// typedef Node5        NL9;
// typedef Node5        NL10;
// typedef Node5        NL11;
// typedef Node5        NL12;
// typedef Node5        NL13;
// typedef Node5        NL14;
// typedef Node5        NL15;

`endif // TRIE_VH