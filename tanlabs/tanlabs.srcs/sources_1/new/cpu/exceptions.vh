`ifndef EXCEPTIONS_VH_H
`define EXCEPTIONS_VH_H

// [have exception (1)] [interrupt/exception (1)] [exception code (4)]
 typedef enum logic [5:0] {
    EC_NONE = 6'b000000,
    // exception
    EC_INSTRUCTION_ADDR_MISALIGNED = 6'b100000,
    EC_INSTRUCTION_ACCESS_FAULT = 6'b100001,
    EC_ILLEGAL_INSTRUCTION = 6'b100010,
    EC_BREAKPOINT = 6'b100011,
    EC_LOAD_ADDR_MISALIGNED = 6'b100100,
    EC_LOAD_ACCESS_FAULT = 6'b100101,
    EC_STORE_ADDR_MISALIGNED = 6'b100110,
    EC_STORE_ACCESS_FAULT = 6'b100111,
    EC_ECALL_FROM_U = 6'b101000,
    EC_ECALL_FROM_S = 6'b101001,
    EC_ECALL_FROM_M = 6'b101011,
    EC_INSTRUCTION_PAGE_FAULT = 6'b101100,
    EC_LOAD_PAGE_FAULT = 6'b101101,
    EC_STORE_PAGE_FAULT = 6'b101111,
    // interrupt
    EC_S_SOFT = 6'b110001,
    EC_M_SOFT = 6'b110011,
    EC_S_TIMER = 6'b110101,
    EC_M_TIMER = 6'b110111,
    EC_S_EXT = 6'b111001,
    EC_M_EXT = 6'b111011
 } exception_t;


 typedef enum logic[1:0] {
    PRIVILEGE_U = 2'b00,
    PRIVILEGE_S = 2'b01,
    // 10 is reserved
    PRIVILEGE_M = 2'b11
 } privilege_t;

`endif
