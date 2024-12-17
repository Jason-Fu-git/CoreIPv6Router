/*

Copyright (c) 2015-2016 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1 ns / 1 ps

/*
 * Wishbone 32 port multiplexer
 */
module bram_mux #
(
    parameter DATA_WIDTH = 32,                    // width of data bus in bits (8, 16, 32, or 64)
    parameter ADDR_WIDTH = 32,                    // width of address bus in bits
    parameter SELECT_WIDTH = (DATA_WIDTH/8)       // width of word select bus (1, 2, 4, or 8)
)
(
    input  wire                    clk,
    input  wire                    rst,

    /*
     * Wishbone master input
     */
    input  wire [ADDR_WIDTH-1:0]   wbm_adr_i,     // ADR_I() address input
    input  wire [DATA_WIDTH-1:0]   wbm_dat_i,     // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbm_dat_o,     // DAT_O() data out
    input  wire                    wbm_we_i,      // WE_I write enable input
    input  wire [SELECT_WIDTH-1:0] wbm_sel_i,     // SEL_I() select input
    input  wire                    wbm_stb_i,     // STB_I strobe input
    output wire                    wbm_ack_o,     // ACK_O acknowledge output
    output wire                    wbm_err_o,     // ERR_O error output
    output wire                    wbm_rty_o,     // RTY_O retry output
    input  wire                    wbm_cyc_i,     // CYC_I cycle input

    /*
     * Wishbone slave 0 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs0_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs0_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs0_dat_o,    // DAT_O() data out
    output wire                    wbs0_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs0_sel_o,    // SEL_O() select output
    output wire                    wbs0_stb_o,    // STB_O strobe output
    input  wire                    wbs0_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs0_err_i,    // ERR_I error input
    input  wire                    wbs0_rty_i,    // RTY_I retry input
    output wire                    wbs0_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 0 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs0_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs0_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 1 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs1_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs1_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs1_dat_o,    // DAT_O() data out
    output wire                    wbs1_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs1_sel_o,    // SEL_O() select output
    output wire                    wbs1_stb_o,    // STB_O strobe output
    input  wire                    wbs1_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs1_err_i,    // ERR_I error input
    input  wire                    wbs1_rty_i,    // RTY_I retry input
    output wire                    wbs1_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 1 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs1_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs1_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 2 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs2_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs2_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs2_dat_o,    // DAT_O() data out
    output wire                    wbs2_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs2_sel_o,    // SEL_O() select output
    output wire                    wbs2_stb_o,    // STB_O strobe output
    input  wire                    wbs2_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs2_err_i,    // ERR_I error input
    input  wire                    wbs2_rty_i,    // RTY_I retry input
    output wire                    wbs2_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 2 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs2_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs2_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 3 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs3_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs3_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs3_dat_o,    // DAT_O() data out
    output wire                    wbs3_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs3_sel_o,    // SEL_O() select output
    output wire                    wbs3_stb_o,    // STB_O strobe output
    input  wire                    wbs3_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs3_err_i,    // ERR_I error input
    input  wire                    wbs3_rty_i,    // RTY_I retry input
    output wire                    wbs3_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 3 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs3_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs3_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 4 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs4_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs4_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs4_dat_o,    // DAT_O() data out
    output wire                    wbs4_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs4_sel_o,    // SEL_O() select output
    output wire                    wbs4_stb_o,    // STB_O strobe output
    input  wire                    wbs4_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs4_err_i,    // ERR_I error input
    input  wire                    wbs4_rty_i,    // RTY_I retry input
    output wire                    wbs4_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 4 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs4_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs4_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 5 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs5_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs5_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs5_dat_o,    // DAT_O() data out
    output wire                    wbs5_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs5_sel_o,    // SEL_O() select output
    output wire                    wbs5_stb_o,    // STB_O strobe output
    input  wire                    wbs5_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs5_err_i,    // ERR_I error input
    input  wire                    wbs5_rty_i,    // RTY_I retry input
    output wire                    wbs5_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 5 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs5_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs5_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 6 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs6_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs6_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs6_dat_o,    // DAT_O() data out
    output wire                    wbs6_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs6_sel_o,    // SEL_O() select output
    output wire                    wbs6_stb_o,    // STB_O strobe output
    input  wire                    wbs6_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs6_err_i,    // ERR_I error input
    input  wire                    wbs6_rty_i,    // RTY_I retry input
    output wire                    wbs6_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 6 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs6_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs6_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 7 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs7_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs7_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs7_dat_o,    // DAT_O() data out
    output wire                    wbs7_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs7_sel_o,    // SEL_O() select output
    output wire                    wbs7_stb_o,    // STB_O strobe output
    input  wire                    wbs7_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs7_err_i,    // ERR_I error input
    input  wire                    wbs7_rty_i,    // RTY_I retry input
    output wire                    wbs7_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 7 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs7_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs7_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 8 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs8_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs8_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs8_dat_o,    // DAT_O() data out
    output wire                    wbs8_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs8_sel_o,    // SEL_O() select output
    output wire                    wbs8_stb_o,    // STB_O strobe output
    input  wire                    wbs8_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs8_err_i,    // ERR_I error input
    input  wire                    wbs8_rty_i,    // RTY_I retry input
    output wire                    wbs8_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 8 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs8_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs8_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 9 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs9_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs9_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs9_dat_o,    // DAT_O() data out
    output wire                    wbs9_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs9_sel_o,    // SEL_O() select output
    output wire                    wbs9_stb_o,    // STB_O strobe output
    input  wire                    wbs9_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs9_err_i,    // ERR_I error input
    input  wire                    wbs9_rty_i,    // RTY_I retry input
    output wire                    wbs9_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 9 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs9_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs9_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 10 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs10_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs10_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs10_dat_o,    // DAT_O() data out
    output wire                    wbs10_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs10_sel_o,    // SEL_O() select output
    output wire                    wbs10_stb_o,    // STB_O strobe output
    input  wire                    wbs10_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs10_err_i,    // ERR_I error input
    input  wire                    wbs10_rty_i,    // RTY_I retry input
    output wire                    wbs10_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 10 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs10_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs10_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 11 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs11_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs11_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs11_dat_o,    // DAT_O() data out
    output wire                    wbs11_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs11_sel_o,    // SEL_O() select output
    output wire                    wbs11_stb_o,    // STB_O strobe output
    input  wire                    wbs11_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs11_err_i,    // ERR_I error input
    input  wire                    wbs11_rty_i,    // RTY_I retry input
    output wire                    wbs11_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 11 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs11_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs11_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 12 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs12_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs12_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs12_dat_o,    // DAT_O() data out
    output wire                    wbs12_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs12_sel_o,    // SEL_O() select output
    output wire                    wbs12_stb_o,    // STB_O strobe output
    input  wire                    wbs12_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs12_err_i,    // ERR_I error input
    input  wire                    wbs12_rty_i,    // RTY_I retry input
    output wire                    wbs12_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 12 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs12_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs12_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 13 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs13_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs13_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs13_dat_o,    // DAT_O() data out
    output wire                    wbs13_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs13_sel_o,    // SEL_O() select output
    output wire                    wbs13_stb_o,    // STB_O strobe output
    input  wire                    wbs13_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs13_err_i,    // ERR_I error input
    input  wire                    wbs13_rty_i,    // RTY_I retry input
    output wire                    wbs13_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 13 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs13_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs13_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 14 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs14_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs14_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs14_dat_o,    // DAT_O() data out
    output wire                    wbs14_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs14_sel_o,    // SEL_O() select output
    output wire                    wbs14_stb_o,    // STB_O strobe output
    input  wire                    wbs14_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs14_err_i,    // ERR_I error input
    input  wire                    wbs14_rty_i,    // RTY_I retry input
    output wire                    wbs14_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 14 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs14_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs14_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 15 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs15_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs15_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs15_dat_o,    // DAT_O() data out
    output wire                    wbs15_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs15_sel_o,    // SEL_O() select output
    output wire                    wbs15_stb_o,    // STB_O strobe output
    input  wire                    wbs15_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs15_err_i,    // ERR_I error input
    input  wire                    wbs15_rty_i,    // RTY_I retry input
    output wire                    wbs15_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 15 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs15_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs15_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 16 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs16_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs16_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs16_dat_o,    // DAT_O() data out
    output wire                    wbs16_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs16_sel_o,    // SEL_O() select output
    output wire                    wbs16_stb_o,    // STB_O strobe output
    input  wire                    wbs16_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs16_err_i,    // ERR_I error input
    input  wire                    wbs16_rty_i,    // RTY_I retry input
    output wire                    wbs16_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 16 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs16_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs16_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 17 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs17_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs17_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs17_dat_o,    // DAT_O() data out
    output wire                    wbs17_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs17_sel_o,    // SEL_O() select output
    output wire                    wbs17_stb_o,    // STB_O strobe output
    input  wire                    wbs17_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs17_err_i,    // ERR_I error input
    input  wire                    wbs17_rty_i,    // RTY_I retry input
    output wire                    wbs17_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 17 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs17_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs17_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 18 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs18_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs18_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs18_dat_o,    // DAT_O() data out
    output wire                    wbs18_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs18_sel_o,    // SEL_O() select output
    output wire                    wbs18_stb_o,    // STB_O strobe output
    input  wire                    wbs18_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs18_err_i,    // ERR_I error input
    input  wire                    wbs18_rty_i,    // RTY_I retry input
    output wire                    wbs18_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 18 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs18_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs18_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 19 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs19_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs19_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs19_dat_o,    // DAT_O() data out
    output wire                    wbs19_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs19_sel_o,    // SEL_O() select output
    output wire                    wbs19_stb_o,    // STB_O strobe output
    input  wire                    wbs19_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs19_err_i,    // ERR_I error input
    input  wire                    wbs19_rty_i,    // RTY_I retry input
    output wire                    wbs19_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 19 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs19_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs19_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 20 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs20_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs20_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs20_dat_o,    // DAT_O() data out
    output wire                    wbs20_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs20_sel_o,    // SEL_O() select output
    output wire                    wbs20_stb_o,    // STB_O strobe output
    input  wire                    wbs20_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs20_err_i,    // ERR_I error input
    input  wire                    wbs20_rty_i,    // RTY_I retry input
    output wire                    wbs20_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 20 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs20_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs20_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 21 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs21_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs21_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs21_dat_o,    // DAT_O() data out
    output wire                    wbs21_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs21_sel_o,    // SEL_O() select output
    output wire                    wbs21_stb_o,    // STB_O strobe output
    input  wire                    wbs21_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs21_err_i,    // ERR_I error input
    input  wire                    wbs21_rty_i,    // RTY_I retry input
    output wire                    wbs21_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 21 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs21_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs21_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 22 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs22_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs22_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs22_dat_o,    // DAT_O() data out
    output wire                    wbs22_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs22_sel_o,    // SEL_O() select output
    output wire                    wbs22_stb_o,    // STB_O strobe output
    input  wire                    wbs22_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs22_err_i,    // ERR_I error input
    input  wire                    wbs22_rty_i,    // RTY_I retry input
    output wire                    wbs22_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 22 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs22_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs22_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 23 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs23_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs23_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs23_dat_o,    // DAT_O() data out
    output wire                    wbs23_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs23_sel_o,    // SEL_O() select output
    output wire                    wbs23_stb_o,    // STB_O strobe output
    input  wire                    wbs23_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs23_err_i,    // ERR_I error input
    input  wire                    wbs23_rty_i,    // RTY_I retry input
    output wire                    wbs23_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 23 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs23_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs23_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 24 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs24_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs24_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs24_dat_o,    // DAT_O() data out
    output wire                    wbs24_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs24_sel_o,    // SEL_O() select output
    output wire                    wbs24_stb_o,    // STB_O strobe output
    input  wire                    wbs24_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs24_err_i,    // ERR_I error input
    input  wire                    wbs24_rty_i,    // RTY_I retry input
    output wire                    wbs24_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 24 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs24_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs24_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 25 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs25_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs25_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs25_dat_o,    // DAT_O() data out
    output wire                    wbs25_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs25_sel_o,    // SEL_O() select output
    output wire                    wbs25_stb_o,    // STB_O strobe output
    input  wire                    wbs25_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs25_err_i,    // ERR_I error input
    input  wire                    wbs25_rty_i,    // RTY_I retry input
    output wire                    wbs25_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 25 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs25_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs25_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 26 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs26_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs26_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs26_dat_o,    // DAT_O() data out
    output wire                    wbs26_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs26_sel_o,    // SEL_O() select output
    output wire                    wbs26_stb_o,    // STB_O strobe output
    input  wire                    wbs26_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs26_err_i,    // ERR_I error input
    input  wire                    wbs26_rty_i,    // RTY_I retry input
    output wire                    wbs26_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 26 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs26_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs26_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 27 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs27_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs27_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs27_dat_o,    // DAT_O() data out
    output wire                    wbs27_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs27_sel_o,    // SEL_O() select output
    output wire                    wbs27_stb_o,    // STB_O strobe output
    input  wire                    wbs27_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs27_err_i,    // ERR_I error input
    input  wire                    wbs27_rty_i,    // RTY_I retry input
    output wire                    wbs27_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 27 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs27_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs27_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 28 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs28_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs28_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs28_dat_o,    // DAT_O() data out
    output wire                    wbs28_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs28_sel_o,    // SEL_O() select output
    output wire                    wbs28_stb_o,    // STB_O strobe output
    input  wire                    wbs28_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs28_err_i,    // ERR_I error input
    input  wire                    wbs28_rty_i,    // RTY_I retry input
    output wire                    wbs28_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 28 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs28_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs28_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 29 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs29_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs29_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs29_dat_o,    // DAT_O() data out
    output wire                    wbs29_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs29_sel_o,    // SEL_O() select output
    output wire                    wbs29_stb_o,    // STB_O strobe output
    input  wire                    wbs29_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs29_err_i,    // ERR_I error input
    input  wire                    wbs29_rty_i,    // RTY_I retry input
    output wire                    wbs29_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 29 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs29_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs29_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 30 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs30_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs30_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs30_dat_o,    // DAT_O() data out
    output wire                    wbs30_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs30_sel_o,    // SEL_O() select output
    output wire                    wbs30_stb_o,    // STB_O strobe output
    input  wire                    wbs30_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs30_err_i,    // ERR_I error input
    input  wire                    wbs30_rty_i,    // RTY_I retry input
    output wire                    wbs30_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 30 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs30_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs30_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 31 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs31_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs31_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs31_dat_o,    // DAT_O() data out
    output wire                    wbs31_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs31_sel_o,    // SEL_O() select output
    output wire                    wbs31_stb_o,    // STB_O strobe output
    input  wire                    wbs31_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs31_err_i,    // ERR_I error input
    input  wire                    wbs31_rty_i,    // RTY_I retry input
    output wire                    wbs31_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 31 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs31_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs31_addr_msk  // Slave address prefix mask
);

wire wbs0_match = ~|((wbm_adr_i ^ wbs0_addr) & wbs0_addr_msk);
wire wbs1_match = ~|((wbm_adr_i ^ wbs1_addr) & wbs1_addr_msk);
wire wbs2_match = ~|((wbm_adr_i ^ wbs2_addr) & wbs2_addr_msk);
wire wbs3_match = ~|((wbm_adr_i ^ wbs3_addr) & wbs3_addr_msk);
wire wbs4_match = ~|((wbm_adr_i ^ wbs4_addr) & wbs4_addr_msk);
wire wbs5_match = ~|((wbm_adr_i ^ wbs5_addr) & wbs5_addr_msk);
wire wbs6_match = ~|((wbm_adr_i ^ wbs6_addr) & wbs6_addr_msk);
wire wbs7_match = ~|((wbm_adr_i ^ wbs7_addr) & wbs7_addr_msk);
wire wbs8_match = ~|((wbm_adr_i ^ wbs8_addr) & wbs8_addr_msk);
wire wbs9_match = ~|((wbm_adr_i ^ wbs9_addr) & wbs9_addr_msk);
wire wbs10_match = ~|((wbm_adr_i ^ wbs10_addr) & wbs10_addr_msk);
wire wbs11_match = ~|((wbm_adr_i ^ wbs11_addr) & wbs11_addr_msk);
wire wbs12_match = ~|((wbm_adr_i ^ wbs12_addr) & wbs12_addr_msk);
wire wbs13_match = ~|((wbm_adr_i ^ wbs13_addr) & wbs13_addr_msk);
wire wbs14_match = ~|((wbm_adr_i ^ wbs14_addr) & wbs14_addr_msk);
wire wbs15_match = ~|((wbm_adr_i ^ wbs15_addr) & wbs15_addr_msk);
wire wbs16_match = ~|((wbm_adr_i ^ wbs16_addr) & wbs16_addr_msk);
wire wbs17_match = ~|((wbm_adr_i ^ wbs17_addr) & wbs17_addr_msk);
wire wbs18_match = ~|((wbm_adr_i ^ wbs18_addr) & wbs18_addr_msk);
wire wbs19_match = ~|((wbm_adr_i ^ wbs19_addr) & wbs19_addr_msk);
wire wbs20_match = ~|((wbm_adr_i ^ wbs20_addr) & wbs20_addr_msk);
wire wbs21_match = ~|((wbm_adr_i ^ wbs21_addr) & wbs21_addr_msk);
wire wbs22_match = ~|((wbm_adr_i ^ wbs22_addr) & wbs22_addr_msk);
wire wbs23_match = ~|((wbm_adr_i ^ wbs23_addr) & wbs23_addr_msk);
wire wbs24_match = ~|((wbm_adr_i ^ wbs24_addr) & wbs24_addr_msk);
wire wbs25_match = ~|((wbm_adr_i ^ wbs25_addr) & wbs25_addr_msk);
wire wbs26_match = ~|((wbm_adr_i ^ wbs26_addr) & wbs26_addr_msk);
wire wbs27_match = ~|((wbm_adr_i ^ wbs27_addr) & wbs27_addr_msk);
wire wbs28_match = ~|((wbm_adr_i ^ wbs28_addr) & wbs28_addr_msk);
wire wbs29_match = ~|((wbm_adr_i ^ wbs29_addr) & wbs29_addr_msk);
wire wbs30_match = ~|((wbm_adr_i ^ wbs30_addr) & wbs30_addr_msk);
wire wbs31_match = ~|((wbm_adr_i ^ wbs31_addr) & wbs31_addr_msk);

wire wbs0_sel = wbs0_match;
wire wbs1_sel = wbs1_match & ~(wbs0_match);
wire wbs2_sel = wbs2_match & ~(wbs0_match | wbs1_match);
wire wbs3_sel = wbs3_match & ~(wbs0_match | wbs1_match | wbs2_match);
wire wbs4_sel = wbs4_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match);
wire wbs5_sel = wbs5_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match);
wire wbs6_sel = wbs6_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match);
wire wbs7_sel = wbs7_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match);
wire wbs8_sel = wbs8_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match);
wire wbs9_sel = wbs9_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match);
wire wbs10_sel = wbs10_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match);
wire wbs11_sel = wbs11_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match);
wire wbs12_sel = wbs12_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match);
wire wbs13_sel = wbs13_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match);
wire wbs14_sel = wbs14_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match);
wire wbs15_sel = wbs15_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match);
wire wbs16_sel = wbs16_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match);
wire wbs17_sel = wbs17_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match);
wire wbs18_sel = wbs18_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match);
wire wbs19_sel = wbs19_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match);
wire wbs20_sel = wbs20_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match);
wire wbs21_sel = wbs21_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match);
wire wbs22_sel = wbs22_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match | wbs21_match);
wire wbs23_sel = wbs23_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match | wbs21_match | wbs22_match);
wire wbs24_sel = wbs24_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match | wbs21_match | wbs22_match | wbs23_match);
wire wbs25_sel = wbs25_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match | wbs21_match | wbs22_match | wbs23_match | wbs24_match);
wire wbs26_sel = wbs26_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match | wbs21_match | wbs22_match | wbs23_match | wbs24_match | wbs25_match);
wire wbs27_sel = wbs27_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match | wbs21_match | wbs22_match | wbs23_match | wbs24_match | wbs25_match | wbs26_match);
wire wbs28_sel = wbs28_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match | wbs21_match | wbs22_match | wbs23_match | wbs24_match | wbs25_match | wbs26_match | wbs27_match);
wire wbs29_sel = wbs29_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match | wbs21_match | wbs22_match | wbs23_match | wbs24_match | wbs25_match | wbs26_match | wbs27_match | wbs28_match);
wire wbs30_sel = wbs30_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match | wbs21_match | wbs22_match | wbs23_match | wbs24_match | wbs25_match | wbs26_match | wbs27_match | wbs28_match | wbs29_match);
wire wbs31_sel = wbs31_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match | wbs7_match | wbs8_match | wbs9_match | wbs10_match | wbs11_match | wbs12_match | wbs13_match | wbs14_match | wbs15_match | wbs16_match | wbs17_match | wbs18_match | wbs19_match | wbs20_match | wbs21_match | wbs22_match | wbs23_match | wbs24_match | wbs25_match | wbs26_match | wbs27_match | wbs28_match | wbs29_match | wbs30_match);

wire master_cycle = wbm_cyc_i & wbm_stb_i;

wire select_error = ~(wbs0_sel | wbs1_sel | wbs2_sel | wbs3_sel | wbs4_sel | wbs5_sel | wbs6_sel | wbs7_sel | wbs8_sel | wbs9_sel | wbs10_sel | wbs11_sel | wbs12_sel | wbs13_sel | wbs14_sel | wbs15_sel | wbs16_sel | wbs17_sel | wbs18_sel | wbs19_sel | wbs20_sel | wbs21_sel | wbs22_sel | wbs23_sel | wbs24_sel | wbs25_sel | wbs26_sel | wbs27_sel | wbs28_sel | wbs29_sel | wbs30_sel | wbs31_sel) & master_cycle;

// master
assign wbm_dat_o = wbs0_sel ? wbs0_dat_i :
                   wbs1_sel ? wbs1_dat_i :
                   wbs2_sel ? wbs2_dat_i :
                   wbs3_sel ? wbs3_dat_i :
                   wbs4_sel ? wbs4_dat_i :
                   wbs5_sel ? wbs5_dat_i :
                   wbs6_sel ? wbs6_dat_i :
                   wbs7_sel ? wbs7_dat_i :
                   wbs8_sel ? wbs8_dat_i :
                   wbs9_sel ? wbs9_dat_i :
                   wbs10_sel ? wbs10_dat_i :
                   wbs11_sel ? wbs11_dat_i :
                   wbs12_sel ? wbs12_dat_i :
                   wbs13_sel ? wbs13_dat_i :
                   wbs14_sel ? wbs14_dat_i :
                   wbs15_sel ? wbs15_dat_i :
                   wbs16_sel ? wbs16_dat_i :
                   wbs17_sel ? wbs17_dat_i :
                   wbs18_sel ? wbs18_dat_i :
                   wbs19_sel ? wbs19_dat_i :
                   wbs20_sel ? wbs20_dat_i :
                   wbs21_sel ? wbs21_dat_i :
                   wbs22_sel ? wbs22_dat_i :
                   wbs23_sel ? wbs23_dat_i :
                   wbs24_sel ? wbs24_dat_i :
                   wbs25_sel ? wbs25_dat_i :
                   wbs26_sel ? wbs26_dat_i :
                   wbs27_sel ? wbs27_dat_i :
                   wbs28_sel ? wbs28_dat_i :
                   wbs29_sel ? wbs29_dat_i :
                   wbs30_sel ? wbs30_dat_i :
                   wbs31_sel ? wbs31_dat_i :
                   {DATA_WIDTH{1'b0}};

assign wbm_ack_o = wbs0_ack_i |
                   wbs1_ack_i |
                   wbs2_ack_i |
                   wbs3_ack_i |
                   wbs4_ack_i |
                   wbs5_ack_i |
                   wbs6_ack_i |
                   wbs7_ack_i |
                   wbs8_ack_i |
                   wbs9_ack_i |
                   wbs10_ack_i |
                   wbs11_ack_i |
                   wbs12_ack_i |
                   wbs13_ack_i |
                   wbs14_ack_i |
                   wbs15_ack_i |
                   wbs16_ack_i |
                   wbs17_ack_i |
                   wbs18_ack_i |
                   wbs19_ack_i |
                   wbs20_ack_i |
                   wbs21_ack_i |
                   wbs22_ack_i |
                   wbs23_ack_i |
                   wbs24_ack_i |
                   wbs25_ack_i |
                   wbs26_ack_i |
                   wbs27_ack_i |
                   wbs28_ack_i |
                   wbs29_ack_i |
                   wbs30_ack_i |
                   wbs31_ack_i;

assign wbm_err_o = wbs0_err_i |
                   wbs1_err_i |
                   wbs2_err_i |
                   wbs3_err_i |
                   wbs4_err_i |
                   wbs5_err_i |
                   wbs6_err_i |
                   wbs7_err_i |
                   wbs8_err_i |
                   wbs9_err_i |
                   wbs10_err_i |
                   wbs11_err_i |
                   wbs12_err_i |
                   wbs13_err_i |
                   wbs14_err_i |
                   wbs15_err_i |
                   wbs16_err_i |
                   wbs17_err_i |
                   wbs18_err_i |
                   wbs19_err_i |
                   wbs20_err_i |
                   wbs21_err_i |
                   wbs22_err_i |
                   wbs23_err_i |
                   wbs24_err_i |
                   wbs25_err_i |
                   wbs26_err_i |
                   wbs27_err_i |
                   wbs28_err_i |
                   wbs29_err_i |
                   wbs30_err_i |
                   wbs31_err_i |
                   select_error;

assign wbm_rty_o = wbs0_rty_i |
                   wbs1_rty_i |
                   wbs2_rty_i |
                   wbs3_rty_i |
                   wbs4_rty_i |
                   wbs5_rty_i |
                   wbs6_rty_i |
                   wbs7_rty_i |
                   wbs8_rty_i |
                   wbs9_rty_i |
                   wbs10_rty_i |
                   wbs11_rty_i |
                   wbs12_rty_i |
                   wbs13_rty_i |
                   wbs14_rty_i |
                   wbs15_rty_i |
                   wbs16_rty_i |
                   wbs17_rty_i |
                   wbs18_rty_i |
                   wbs19_rty_i |
                   wbs20_rty_i |
                   wbs21_rty_i |
                   wbs22_rty_i |
                   wbs23_rty_i |
                   wbs24_rty_i |
                   wbs25_rty_i |
                   wbs26_rty_i |
                   wbs27_rty_i |
                   wbs28_rty_i |
                   wbs29_rty_i |
                   wbs30_rty_i |
                   wbs31_rty_i;

// slave 0
assign wbs0_adr_o = wbm_adr_i;
assign wbs0_dat_o = wbm_dat_i;
assign wbs0_we_o = wbm_we_i & wbs0_sel;
assign wbs0_sel_o = wbm_sel_i;
assign wbs0_stb_o = wbm_stb_i & wbs0_sel;
assign wbs0_cyc_o = wbm_cyc_i & wbs0_sel;

// slave 1
assign wbs1_adr_o = wbm_adr_i;
assign wbs1_dat_o = wbm_dat_i;
assign wbs1_we_o = wbm_we_i & wbs1_sel;
assign wbs1_sel_o = wbm_sel_i;
assign wbs1_stb_o = wbm_stb_i & wbs1_sel;
assign wbs1_cyc_o = wbm_cyc_i & wbs1_sel;

// slave 2
assign wbs2_adr_o = wbm_adr_i;
assign wbs2_dat_o = wbm_dat_i;
assign wbs2_we_o = wbm_we_i & wbs2_sel;
assign wbs2_sel_o = wbm_sel_i;
assign wbs2_stb_o = wbm_stb_i & wbs2_sel;
assign wbs2_cyc_o = wbm_cyc_i & wbs2_sel;

// slave 3
assign wbs3_adr_o = wbm_adr_i;
assign wbs3_dat_o = wbm_dat_i;
assign wbs3_we_o = wbm_we_i & wbs3_sel;
assign wbs3_sel_o = wbm_sel_i;
assign wbs3_stb_o = wbm_stb_i & wbs3_sel;
assign wbs3_cyc_o = wbm_cyc_i & wbs3_sel;

// slave 4
assign wbs4_adr_o = wbm_adr_i;
assign wbs4_dat_o = wbm_dat_i;
assign wbs4_we_o = wbm_we_i & wbs4_sel;
assign wbs4_sel_o = wbm_sel_i;
assign wbs4_stb_o = wbm_stb_i & wbs4_sel;
assign wbs4_cyc_o = wbm_cyc_i & wbs4_sel;

// slave 5
assign wbs5_adr_o = wbm_adr_i;
assign wbs5_dat_o = wbm_dat_i;
assign wbs5_we_o = wbm_we_i & wbs5_sel;
assign wbs5_sel_o = wbm_sel_i;
assign wbs5_stb_o = wbm_stb_i & wbs5_sel;
assign wbs5_cyc_o = wbm_cyc_i & wbs5_sel;

// slave 6
assign wbs6_adr_o = wbm_adr_i;
assign wbs6_dat_o = wbm_dat_i;
assign wbs6_we_o = wbm_we_i & wbs6_sel;
assign wbs6_sel_o = wbm_sel_i;
assign wbs6_stb_o = wbm_stb_i & wbs6_sel;
assign wbs6_cyc_o = wbm_cyc_i & wbs6_sel;

// slave 7
assign wbs7_adr_o = wbm_adr_i;
assign wbs7_dat_o = wbm_dat_i;
assign wbs7_we_o = wbm_we_i & wbs7_sel;
assign wbs7_sel_o = wbm_sel_i;
assign wbs7_stb_o = wbm_stb_i & wbs7_sel;
assign wbs7_cyc_o = wbm_cyc_i & wbs7_sel;

// slave 8
assign wbs8_adr_o = wbm_adr_i;
assign wbs8_dat_o = wbm_dat_i;
assign wbs8_we_o = wbm_we_i & wbs8_sel;
assign wbs8_sel_o = wbm_sel_i;
assign wbs8_stb_o = wbm_stb_i & wbs8_sel;
assign wbs8_cyc_o = wbm_cyc_i & wbs8_sel;

// slave 9
assign wbs9_adr_o = wbm_adr_i;
assign wbs9_dat_o = wbm_dat_i;
assign wbs9_we_o = wbm_we_i & wbs9_sel;
assign wbs9_sel_o = wbm_sel_i;
assign wbs9_stb_o = wbm_stb_i & wbs9_sel;
assign wbs9_cyc_o = wbm_cyc_i & wbs9_sel;

// slave 10
assign wbs10_adr_o = wbm_adr_i;
assign wbs10_dat_o = wbm_dat_i;
assign wbs10_we_o = wbm_we_i & wbs10_sel;
assign wbs10_sel_o = wbm_sel_i;
assign wbs10_stb_o = wbm_stb_i & wbs10_sel;
assign wbs10_cyc_o = wbm_cyc_i & wbs10_sel;

// slave 11
assign wbs11_adr_o = wbm_adr_i;
assign wbs11_dat_o = wbm_dat_i;
assign wbs11_we_o = wbm_we_i & wbs11_sel;
assign wbs11_sel_o = wbm_sel_i;
assign wbs11_stb_o = wbm_stb_i & wbs11_sel;
assign wbs11_cyc_o = wbm_cyc_i & wbs11_sel;

// slave 12
assign wbs12_adr_o = wbm_adr_i;
assign wbs12_dat_o = wbm_dat_i;
assign wbs12_we_o = wbm_we_i & wbs12_sel;
assign wbs12_sel_o = wbm_sel_i;
assign wbs12_stb_o = wbm_stb_i & wbs12_sel;
assign wbs12_cyc_o = wbm_cyc_i & wbs12_sel;

// slave 13
assign wbs13_adr_o = wbm_adr_i;
assign wbs13_dat_o = wbm_dat_i;
assign wbs13_we_o = wbm_we_i & wbs13_sel;
assign wbs13_sel_o = wbm_sel_i;
assign wbs13_stb_o = wbm_stb_i & wbs13_sel;
assign wbs13_cyc_o = wbm_cyc_i & wbs13_sel;

// slave 14
assign wbs14_adr_o = wbm_adr_i;
assign wbs14_dat_o = wbm_dat_i;
assign wbs14_we_o = wbm_we_i & wbs14_sel;
assign wbs14_sel_o = wbm_sel_i;
assign wbs14_stb_o = wbm_stb_i & wbs14_sel;
assign wbs14_cyc_o = wbm_cyc_i & wbs14_sel;

// slave 15
assign wbs15_adr_o = wbm_adr_i;
assign wbs15_dat_o = wbm_dat_i;
assign wbs15_we_o = wbm_we_i & wbs15_sel;
assign wbs15_sel_o = wbm_sel_i;
assign wbs15_stb_o = wbm_stb_i & wbs15_sel;
assign wbs15_cyc_o = wbm_cyc_i & wbs15_sel;

// slave 16
assign wbs16_adr_o = wbm_adr_i;
assign wbs16_dat_o = wbm_dat_i;
assign wbs16_we_o = wbm_we_i & wbs16_sel;
assign wbs16_sel_o = wbm_sel_i;
assign wbs16_stb_o = wbm_stb_i & wbs16_sel;
assign wbs16_cyc_o = wbm_cyc_i & wbs16_sel;

// slave 17
assign wbs17_adr_o = wbm_adr_i;
assign wbs17_dat_o = wbm_dat_i;
assign wbs17_we_o = wbm_we_i & wbs17_sel;
assign wbs17_sel_o = wbm_sel_i;
assign wbs17_stb_o = wbm_stb_i & wbs17_sel;
assign wbs17_cyc_o = wbm_cyc_i & wbs17_sel;

// slave 18
assign wbs18_adr_o = wbm_adr_i;
assign wbs18_dat_o = wbm_dat_i;
assign wbs18_we_o = wbm_we_i & wbs18_sel;
assign wbs18_sel_o = wbm_sel_i;
assign wbs18_stb_o = wbm_stb_i & wbs18_sel;
assign wbs18_cyc_o = wbm_cyc_i & wbs18_sel;

// slave 19
assign wbs19_adr_o = wbm_adr_i;
assign wbs19_dat_o = wbm_dat_i;
assign wbs19_we_o = wbm_we_i & wbs19_sel;
assign wbs19_sel_o = wbm_sel_i;
assign wbs19_stb_o = wbm_stb_i & wbs19_sel;
assign wbs19_cyc_o = wbm_cyc_i & wbs19_sel;

// slave 20
assign wbs20_adr_o = wbm_adr_i;
assign wbs20_dat_o = wbm_dat_i;
assign wbs20_we_o = wbm_we_i & wbs20_sel;
assign wbs20_sel_o = wbm_sel_i;
assign wbs20_stb_o = wbm_stb_i & wbs20_sel;
assign wbs20_cyc_o = wbm_cyc_i & wbs20_sel;

// slave 21
assign wbs21_adr_o = wbm_adr_i;
assign wbs21_dat_o = wbm_dat_i;
assign wbs21_we_o = wbm_we_i & wbs21_sel;
assign wbs21_sel_o = wbm_sel_i;
assign wbs21_stb_o = wbm_stb_i & wbs21_sel;
assign wbs21_cyc_o = wbm_cyc_i & wbs21_sel;

// slave 22
assign wbs22_adr_o = wbm_adr_i;
assign wbs22_dat_o = wbm_dat_i;
assign wbs22_we_o = wbm_we_i & wbs22_sel;
assign wbs22_sel_o = wbm_sel_i;
assign wbs22_stb_o = wbm_stb_i & wbs22_sel;
assign wbs22_cyc_o = wbm_cyc_i & wbs22_sel;

// slave 23
assign wbs23_adr_o = wbm_adr_i;
assign wbs23_dat_o = wbm_dat_i;
assign wbs23_we_o = wbm_we_i & wbs23_sel;
assign wbs23_sel_o = wbm_sel_i;
assign wbs23_stb_o = wbm_stb_i & wbs23_sel;
assign wbs23_cyc_o = wbm_cyc_i & wbs23_sel;

// slave 24
assign wbs24_adr_o = wbm_adr_i;
assign wbs24_dat_o = wbm_dat_i;
assign wbs24_we_o = wbm_we_i & wbs24_sel;
assign wbs24_sel_o = wbm_sel_i;
assign wbs24_stb_o = wbm_stb_i & wbs24_sel;
assign wbs24_cyc_o = wbm_cyc_i & wbs24_sel;

// slave 25
assign wbs25_adr_o = wbm_adr_i;
assign wbs25_dat_o = wbm_dat_i;
assign wbs25_we_o = wbm_we_i & wbs25_sel;
assign wbs25_sel_o = wbm_sel_i;
assign wbs25_stb_o = wbm_stb_i & wbs25_sel;
assign wbs25_cyc_o = wbm_cyc_i & wbs25_sel;

// slave 26
assign wbs26_adr_o = wbm_adr_i;
assign wbs26_dat_o = wbm_dat_i;
assign wbs26_we_o = wbm_we_i & wbs26_sel;
assign wbs26_sel_o = wbm_sel_i;
assign wbs26_stb_o = wbm_stb_i & wbs26_sel;
assign wbs26_cyc_o = wbm_cyc_i & wbs26_sel;

// slave 27
assign wbs27_adr_o = wbm_adr_i;
assign wbs27_dat_o = wbm_dat_i;
assign wbs27_we_o = wbm_we_i & wbs27_sel;
assign wbs27_sel_o = wbm_sel_i;
assign wbs27_stb_o = wbm_stb_i & wbs27_sel;
assign wbs27_cyc_o = wbm_cyc_i & wbs27_sel;

// slave 28
assign wbs28_adr_o = wbm_adr_i;
assign wbs28_dat_o = wbm_dat_i;
assign wbs28_we_o = wbm_we_i & wbs28_sel;
assign wbs28_sel_o = wbm_sel_i;
assign wbs28_stb_o = wbm_stb_i & wbs28_sel;
assign wbs28_cyc_o = wbm_cyc_i & wbs28_sel;

// slave 29
assign wbs29_adr_o = wbm_adr_i;
assign wbs29_dat_o = wbm_dat_i;
assign wbs29_we_o = wbm_we_i & wbs29_sel;
assign wbs29_sel_o = wbm_sel_i;
assign wbs29_stb_o = wbm_stb_i & wbs29_sel;
assign wbs29_cyc_o = wbm_cyc_i & wbs29_sel;

// slave 30
assign wbs30_adr_o = wbm_adr_i;
assign wbs30_dat_o = wbm_dat_i;
assign wbs30_we_o = wbm_we_i & wbs30_sel;
assign wbs30_sel_o = wbm_sel_i;
assign wbs30_stb_o = wbm_stb_i & wbs30_sel;
assign wbs30_cyc_o = wbm_cyc_i & wbs30_sel;

// slave 31
assign wbs31_adr_o = wbm_adr_i;
assign wbs31_dat_o = wbm_dat_i;
assign wbs31_we_o = wbm_we_i & wbs31_sel;
assign wbs31_sel_o = wbm_sel_i;
assign wbs31_stb_o = wbm_stb_i & wbs31_sel;
assign wbs31_cyc_o = wbm_cyc_i & wbs31_sel;


endmodule
