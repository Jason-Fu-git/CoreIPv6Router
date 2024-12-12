`ifndef CSRS_VH_H
`define CSRS_VH_H

parameter CSR_SATP = 12'h180;

parameter CSR_MSTATUS = 12'h300;
parameter CSR_MIE     = 12'h304;
parameter CSR_MTVEC   = 12'h305;
parameter CSR_MSCRATCH= 12'h340;
parameter CSR_MEPC    = 12'h341;
parameter CSR_MCAUSE  = 12'h342;
parameter CSR_MTVAL   = 12'h343;
parameter CSR_MIP     = 12'h344;

parameter CSR_PMPCFG0 = 12'h3a0;
parameter CSR_PMPADDR0 = 12'h3b0;

parameter MIE_MTIE = 7;
parameter MIP_MTIP = 7;

parameter MSTATUS_MPP_H = 12;
parameter MSTATUS_MPP_L = 11;
parameter MSTATUS_MPIE= 7;
parameter MSTATUS_MIE = 3;

parameter MTIME_LADDR    = 32'h0200BFF8; // lower 32 bits of mtime
parameter MTIMECMP_LADDR = 32'h02004000; // lower 32 bits of mtimecmp

parameter MTIME_HADDR    = 32'h0200BFFC; // higher 32 bits of mtime
parameter MTIMECMP_HADDR = 32'h02004004; // higher 32 bits of mtimecmp

parameter DMA_CPU_STB        = 32'h01000000;
parameter DMA_CPU_WE         = 32'h01000004;
parameter DMA_CPU_ADDR       = 32'h01000008;
parameter DMA_CPU_DATA_WIDTH = 32'h0100000C;
parameter DMA_ACK            = 32'h01000010;
parameter DMA_DATA_WIDTH     = 32'h01000014;



`endif
