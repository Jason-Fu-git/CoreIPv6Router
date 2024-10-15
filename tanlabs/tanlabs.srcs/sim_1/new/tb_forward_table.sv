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
  reg ip6_addr;
  reg prefix_len;

  reg next_hop_addr;
  reg ready;
  reg exists;
  // ===========================


  // Clock
  always #5 clk = ~clk;

  // Initial block
  initial begin
    // Initialize Inputs
    clk   = 0;
    rst_p = 1;
    wea_p = 0;

    bram_addr_w = 0;
    bram_data_w = 0;

    ea_p = 0;
    ip6_addr = 0;
    prefix_len = 0;

    // Wait 100 ns for global reset to finish
    #100;
    rst_p = 0;

    // Write Entries
    #100;
    bram_addr_r = 0;  // address
    bram_data_r = {0, 1'b1, 8'd16, 128'h1, 128'hFF800000000000000000000000000000};  // Random data
    wea_p = 1;
    cea_p = 1;

    #100;
    wea_p = 0;
    cea_p = 0;

    #100;

    // Read test
    for (int i = 0; i < 4; i = i + 1) begin
      #100;
      bram_addr = i;  // address
      cea_p = 1;

      #100;
      cea_p = 0;

      #100;
    end

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
      .rea_p(rea_p),
      .wea_p(wea_p),
      .ack_p(ack_p),
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
      .prefix_len(prefix_len),
      .next_hop_addr(next_hop_addr),
      .ready(ready),
      .exists(exists),
      .mem_data(bram_data_r),
      .mem_ack_p(mem_ack_p),
      .mem_addr(bram_addr_r),
      .mem_rea_p(mem_rea_p)
  );

endmodule
