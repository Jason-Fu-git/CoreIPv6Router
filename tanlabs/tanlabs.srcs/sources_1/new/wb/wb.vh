`ifndef _WB_VH_
`define _WB_VH_

// DMA
parameter DMA_CPU_STB           = 32'h01000000;
parameter DMA_CPU_WE            = 32'h01000004;
parameter DMA_CPU_ADDR          = 32'h01000008;
parameter DMA_CPU_DATA_WIDTH    = 32'h0100000C;
parameter DMA_ACK               = 32'h01000010;
parameter DMA_DATA_WIDTH        = 32'h01000014;
parameter DMA_CHECKSUM          = 32'h01000018;
parameter DMA_IN_PORT_ID        = 32'h0100001C;
parameter DMA_OUT_PORT_ID       = 32'h01000020;
parameter DMA_REQUEST           = 32'h01000024;

// IP Config
// Format: [9:8] - index, [3:0] - offset
parameter IP_CONFIG_ADDR     = 32'h40000000;
parameter MAC_CONFIG_ADDR    = 32'h40001000;

// Next Hop Table
// Format: [8:4] - index, [3:0] - offset
parameter NEXTHOP_ADDR  = 32'h41000000;
parameter PORT_ID_ADDR  = 32'h41001000;

`endif // _WB_VH_
