`timescale 1ns / 1ps

module tb_forward_table;

  localparam DATA_WIDTH = 320;
  localparam ADDR_WIDTH = 5;

  // ======= bram =============
  reg clk;
  reg rst_p;

  // control signals
  reg mem_wea_p;  // write enable for this bram
  reg mem_rea_p;  // read enable for this bram
  reg mem_ack_p;  // acknowledge signal

  // address and data
  reg [ADDR_WIDTH-1:0] bram_addr_w;  // address for write
  reg [ADDR_WIDTH-1:0] bram_addr_r;  // address for read
  reg [DATA_WIDTH-1:0] bram_data_w;  // data for write
  reg [DATA_WIDTH-1:0] bram_data_r;  // data for read
  // ==========================

  // ======= ftb ==============
  reg ea_p;
  reg [127:0] ip6_addr;

  reg [127:0] next_hop_addr;
  reg ready;
  reg exists;
  // ===========================


  // Clock
  always #5 clk = ~clk;

  // Initial block
  initial begin
    // Initialize Inputs
    clk = 0;
    rst_p = 1;
    mem_wea_p = 0;
    mem_rea_p = 0;

    bram_addr_w = 0;
    bram_data_w = 0;

    ea_p = 0;
    ip6_addr = 0;

    // Wait 100 ns for global reset to finish
    #100;
    rst_p = 0;

    // ================ Write Entries ================

    // ==== 1 ====
    #100;
    bram_addr_w = 0;
    bram_data_w = {0, 1'b1, 8'd16, 128'h1, 128'h000000000000000000000000000080FF};
    mem_wea_p   = 1;

    #100;
    mem_wea_p = 0;

    // ==== 2 ====
    #100;
    bram_addr_w = 1;
    bram_data_w = {0, 1'b0, 8'd32, 128'h2, 128'h000000000000000000000000CDAB80FF};
    mem_wea_p   = 1;

    #100;
    mem_wea_p = 0;

    // ==== 3 ====
    #100;
    bram_addr_w = 2;
    bram_data_w = {0, 1'b1, 8'd8, 128'h3, 128'h000000000000000000000000000000FF};
    mem_wea_p   = 1;

    #100;
    mem_wea_p = 0;

    // ==== 4 ====
    // do nothing

    // ================ Search Entries ================

    // ==== 1 ====

    // Hit entry 1
    #100;
    ea_p = 1;
    ip6_addr = 128'h000000000000000000000000CDAB80FF;

    #100;
    ea_p = 0;

    // Miss
    #100;
    ea_p = 1;
    ip6_addr = 128'h000000000000000000000000CDAB80FE;

    #100;
    ea_p = 0;

    // Hit entry 3
    #100;
    ea_p = 1;
    ip6_addr = 128'h00000000000000000000000000090FF;

    #100;
    ea_p = 0;

    // Finish the simulation
    $finish;
  end


  // Instantiate the Unit Under Test (UUT)
  bram_controller #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH)
  ) bram_test (
      .clk(clk),
      .rst_p(rst_p),
      .rea_p(mem_rea_p),
      .wea_p(mem_wea_p),
      .ack_p(mem_ack_p),
      .bram_addr_r(bram_addr_r),
      .bram_addr_w(bram_addr_w),
      .bram_data_w(bram_data_w),
      .bram_data_r(bram_data_r)
  );

  forward_table #(
      .BASE_ADDR (2'h0),
      .MAX_ADDR  (2'h3),
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH)
  ) ftb_test (
      .clk(clk),
      .rst_p(rst_p),
      .ea_p(ea_p),
      .ip6_addr(ip6_addr),
      .next_hop_addr(next_hop_addr),
      .ready(ready),
      .exists(exists),
      .mem_data(bram_data_r),
      .mem_ack_p(mem_ack_p),
      .mem_addr(bram_addr_r),
      .mem_rea_p(mem_rea_p)
  );

endmodule
