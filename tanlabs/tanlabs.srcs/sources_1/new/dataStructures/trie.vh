localparam ENTRY_SIZE = 38;

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

typedef Node1 NL0;
typedef Node15Addr8 NL1;
typedef Node15Addr14 NL2;
typedef Node15Addr14 NL3;
typedef Node15Addr14 NL4;
typedef Node11 NL5;
typedef Node5 NL6;
typedef Node5 NL7;
typedef Node5 NL8;
typedef Node5 NL9;
typedef Node5 NL10;
typedef Node5 NL11;
typedef Node5 NL12;
typedef Node5 NL13;
typedef Node5 NL14;
typedef Node5 NL15;
