`timescale 1ns / 1ps
`include "trie.vh"
`include "frame_datapath.vh"

module tb_binary_trie;

  logic clk;
  logic rst_p;

  logic [127:0] pipeline_prefix;  // TODO: pipeline_prefix is file input

  // ===========================
  // Binary Trie
  // ===========================

  // bram signals
  logic [35:0] node_i[16];
  logic [14:0] addr_o[16];
  logic [14:0] init_addr_i[16];
  logic [14:0] next_addr_o[16];  // Addr to be given to the next chip of BRAM
  logic rea_o[16];

  // pipeline inputs
  logic [7:0] max_match_i[16];
  logic [127:0] prefix_i[16];
  logic [7:0] prefix_length_i[16];  // input should be 8N
  logic [4:0] next_hop_addr_i[16];
  fw_frame_beat_t frame_beat_i[16];  // TODO: frame_beat_i[0]
  logic valid_i[16];  // TODO: valid_i[0]
  logic skip_i[16];  // TODO: skip_i[0]
  logic ready_o[16];  // in ready

  // pipeline outputs
  logic [7:0] max_match_o[16];
  logic [127:0] prefix_o[16];
  logic [7:0] prefix_length_o[16];
  logic [4:0] next_hop_addr_o[16];
  fw_frame_beat_t frame_beat_o[16];
  logic valid_o[16];
  logic skip_o[16];
  logic ready_i[16];  // out ready

  // ===========================
  // Block RAMs
  // ===========================

  logic web[16];
  logic [12:0] addrb[16];
  logic [35:0] dinb[16];
  logic [35:0] doutb[16];

  // input
  always_ff @(posedge clk) begin : PinelineInput
    if (rst_p) begin
      max_match_i[0] <= 0;
      prefix_length_i[0] <= 0;
      next_hop_addr_i[0] <= 0;
      prefix_i[0] <= 0;
    end else begin
      if (ready_o[0]) begin
        max_match_i[0] <= 0;
        prefix_length_i[0] <= 0;
        next_hop_addr_i[0] <= 0;
        prefix_i[0] <= pipeline_prefix;
      end
    end
  end


  // link the pipeline
  generate
    for (i = 0; i < 15; i = i + 1) begin : g_links
      assign max_match_i[i+1] = max_match_o[i];
      assign prefix_i[i+1] = prefix_o[i];
      assign prefix_length_i[i+1] = prefix_length_o[i];
      assign next_hop_addr_i[i+1] = next_hop_addr_o[i];
      assign frame_beat_i[i+1] = frame_beat_o[i];
      assign valid_i[i+1] = valid_o[i];
      assign skip_i[i+1] = skip_o[i];
      assign ready_i[i] = ready_o[i+1];

      assign init_addr_i[i+1] = next_addr_o[i];
    end
  endgenerate

  // Instantiate the Unit Under Test (UUT)
  generate
    for (i = 0; i < 16; i = i + 1) begin : g_uuts
      binary_trie uut (
          .clk(clk),
          .rst_p(rst_p),
          .node_i(node_i[i]),
          .addr_o(addr_o[i]),
          .init_addr_i(init_addr_i[i]),
          .next_addr_o(next_addr_o[i]),
          .rea_o(rea_o[i]),
          .max_match_i(max_match_i[i]),
          .prefix_i(prefix_i[i]),
          .prefix_length_i(prefix_length_i[i]),
          .next_hop_addr_i(next_hop_addr_i[i]),
          .frame_beat_i(frame_beat_i[i]),
          .valid_i(valid_i[i]),
          .skip_i(skip_i[i]),
          .ready_o(ready_o[i]),
          .max_match_o(max_match_o[i]),
          .prefix_o(prefix_o[i]),
          .prefix_length_o(prefix_length_o[i]),
          .next_hop_addr_o(next_hop_addr_o[i]),
          .frame_beat_o(frame_beat_o[i]),
          .valid_o(valid_o[i]),
          .skip_o(skip_o[i]),
          .ready_i(ready_i[i])
      );
    end
  endgenerate

  generate
    for (i = 0; i < 16; i = i + 1) begin : g_brams
      blk_mem_bt bram_i (
          .clka (clk),        // input wire clka
          .ena  (rea_o[i]),   // input wire ena
          .wea  (1'b0),       // input wire [0 : 0] wea
          .addra(addr_o[i]),  // input wire [12 : 0] addra
          .dina (0),          // input wire [35 : 0] dina
          .douta(node_i[i]),  // output wire [35 : 0] douta
          .clkb (clk),        // input wire clkb
          .enb  (1'b1),       // input wire enb
          .web  (web[i]),     // input wire [0 : 0] web
          .addrb(addrb[i]),   // input wire [12 : 0] addrb
          .dinb (dinb[i]),    // input wire [35 : 0] dinb
          .doutb(doutb[i])    // output wire [35 : 0] doutb
      );
    end
  endgenerate

  // ===========================
  // Testbench Logic
  // ===========================

  // Always block
  always #5 clk = ~clk;

  // Initial block
  initial begin


    #10000;
    $finish;
  end
endmodule
