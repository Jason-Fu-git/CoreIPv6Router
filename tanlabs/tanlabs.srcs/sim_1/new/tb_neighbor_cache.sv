`timescale 1ns / 1ps

module tb_neighbor_cache;

  // Parameters
  localparam NUM_ENTRIES = 16;
  localparam ENTRY_ADDR_WIDTH = 4;
  localparam REACHABLE_LIMIT = 2000;
  localparam PROBE_LIMIT = 1000;

  // Inputs
  reg clk;
  reg rst_p;
  reg [127:0] IPv6_addr;
  reg [47:0] w_MAC_addr;
  reg [1:0] w_port_id;
  reg rea_p;
  reg wea_p;
  reg uea_p;

  // Outputs
  wire [47:0] r_MAC_addr;
  wire [1:0] r_port_id;
  reg exists;
  reg ready;

  reg should_probe;
  reg [127:0] probe_IPv6_addr;

  // Instantiate the Unit Under Test (UUT)
  neighbor_cache #(
      .NUM_ENTRIES(NUM_ENTRIES),
      .ENTRY_ADDR_WIDTH(ENTRY_ADDR_WIDTH),
      .REACHABLE_LIMIT(REACHABLE_LIMIT),
      .PROBE_LIMIT(PROBE_LIMIT)
  ) dut (
      .clk(clk),
      .rst_p(rst_p),
      .IPv6_addr(IPv6_addr),
      .w_MAC_addr(w_MAC_addr),
      .r_MAC_addr(r_MAC_addr),
      .w_port_id(w_port_id),
      .r_port_id(r_port_id),
      .uea_p(uea_p),
      .wea_p(wea_p),
      .rea_p(rea_p),
      .exists(exists),
      .ready(ready),
      .should_probe(should_probe),
      .probe_IPv6_addr(probe_IPv6_addr)
  );

  // Always block
  always #5 clk = ~clk;

  // Initial block
  initial begin
    // Initialize Inputs
    clk = 0;
    rst_p = 1;
    IPv6_addr = 0;
    w_MAC_addr = 0;
    w_port_id = 0;
    rea_p = 0;
    wea_p = 0;
    uea_p = 0;

    // Wait 1000 ps for global reset to finish
    #1000;
    rst_p = 0;

    // Write Test
    for (int i = 0; i < NUM_ENTRIES * 2; i = i + 1) begin
      #100;
      IPv6_addr = i;  // IPv6 address
      w_MAC_addr = {$urandom, $urandom};  // Random MAC address
      w_port_id = $urandom % 4;  // Random port ID
      wea_p = 1;

      #100;
      wea_p = 0;

      #100;
    end

    // Read test
    for (int i = 0; i < NUM_ENTRIES * 2; i = i + 1) begin
      #100;
      IPv6_addr = i;  // IPv6 address
      rea_p = 1;

      #100;
      rea_p = 0;

      #100;
    end

    // Replace / Update test
    for (int i = NUM_ENTRIES * 2 - 1; i >= 0; i = i - 1) begin
      #100;
      IPv6_addr = i;  // IPv6 address
      w_MAC_addr = {$urandom, $urandom};  // Random MAC address
      w_port_id = $urandom % 4;  // Random port ID
      wea_p = 1;

      #100;
      wea_p = 0;

      #100;
    end

    #6000;

    // First entry reachable
    #100;
    IPv6_addr = NUM_ENTRIES - 1;
    uea_p = 1;

    #100;
    uea_p = 0;

    #100;

    // Third entry reachable
    #100;
    IPv6_addr = NUM_ENTRIES - 3;
    uea_p = 1;

    #100;
    uea_p = 0;

    #100;
    // Wait for the other entries to expire
    #10000;

    // Write test
    #100;
    IPv6_addr = NUM_ENTRIES - 4;
    w_MAC_addr = {$urandom, $urandom};
    w_port_id = $urandom % 4;
    wea_p = 1;

    #100;
    wea_p = 0;

    #100;

    #1000 $finish;
  end
endmodule
