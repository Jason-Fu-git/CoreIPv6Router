`timescale 1ns / 1ps

module trie128(
    input wire clk,
    input wire rst_p,
    input fw_frame_beat_t in,
    output fw_frame_beat_t out,
    input wire in_valid,
    input wire out_ready,
    output reg in_ready,
    output reg out_valid,
    input wire [  4:0] default_next_hop,
    input wire [127:0] addr,
    output reg [  4:0] next_hop
);
    parameter int VC_ADDR_WIDTH [0:16] = {8, 13, 13, 13, 13, 12, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0};
    parameter int VC_BIN_SIZE   [0:15] = {1, 7,  15, 15, 14, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};
    parameter int VC_NODE_WIDTH [0:15] = {54,306,612,612,558,414,54,54,54,54,54,54,54,54,54,54};
    parameter MAX_VC_ADDR_WIDTH        = 13;
    parameter MAX_VC_NODE_WIDTH        = 612;
    parameter BT_ADDR_WIDTH            = 13;
    parameter BT_NODE_WIDTH            = 36;
    // frame_beat
    frame_beat [15:0] frame_beat_in;
    frame_beat [15:0] frame_beat_out;

    for (genvar i = 0; i < 15; i++) begin
        assign frame_beat_in[i+1] = frame_beat_out[i];
    end

    assign frame_beat_in[0] = in.data;

    reg [127:0] next_hop_ip6;
    reg [  1:0] next_hop_iface;

    fwt_lookup fwt_lookup_i (
        .in(next_hop),
        .out(next_hop_ip6),
        .out_iface(next_hop_iface)
    );

    always_comb begin
        out.data = frame_beat_out[15];
        out.data.data.ip6.dst = next_hop_ip6;
        out.data.meta.dest = next_hop_iface;
    end

    // valid, ready
    logic [15:0] trie_in_valid;
    logic [15:0] trie_out_valid;
    logic [15:0] trie_in_ready;
    logic [15:0] trie_out_ready;

    for (genvar i = 0; i < 15; i++) begin
        assign trie_in_valid[i+1] = trie_out_valid[i];
        assign trie_out_ready[i]  = trie_in_ready[i+1];
    end

    assign trie_in_valid[0]   = in_valid;
    assign out_valid          = trie_out_valid[15];
    assign trie_out_ready[15] = out_ready;
    assign in_ready           = trie_in_ready[0];

    // VCTrie

    // node, addr
    logic [15:0][MAX_VC_ADDR_WIDTH-1:0] vc_addr;
    logic [15:0][MAX_VC_NODE_WIDTH-1:0] vc_node;

    logic [15:0][MAX_VC_ADDR_WIDTH-1:0] vc_init_addr_in;
    logic [15:0][MAX_VC_ADDR_WIDTH-1:0] vc_init_addr_out;

    for (genvar i = 0; i < 15; i++) begin
        assign vc_init_addr_in[i+1] = vc_init_addr_out[i];
    end

    assign vc_init_addr_in[0] = addr[0] ? 2 : 1;

    // max_match
    logic [15:0][7:0] vc_max_match_in;
    logic [15:0][7:0] vc_max_match_out;

    for (genvar i = 0; i < 15; i++) begin
        assign vc_max_match_in[i+1] = vc_max_match_out[i+1];
    end

    assign vc_max_match_in[0] = 0;

    // prefix
    logic [15:0][127:0] vc_prefix_in;
    logic [15:0][127:0] vc_prefix_out;

    for (genvar i = 0; i < 15; i++) begin
        assign vc_prefix_in[i+1] = vc_prefix_out[i];
    end

    assign vc_prefix_in[0] = addr;

    // next_hop
    logic [15:0][4:0] vc_next_hop_in;
    logic [15:0][4:0] vc_next_hop_out;

    for (genvar i = 0; i < 15; i++) begin
        assign vc_next_hop_in[i+1] = vc_next_hop_out[i];
    end

    assign vc_next_hop_in[0] = default_next_hop;

    // BTrie

    // node, addr
    logic [15:0][BT_ADDR_WIDTH-1:0] bt_addr;
    logic [15:0][BT_NODE_WIDTH-1:0] bt_node;

    logic [15:0][BT_ADDR_WIDTH-1:0] bt_init_addr_in;
    logic [15:0][BT_ADDR_WIDTH-1:0] bt_init_addr_out;

    for (genvar i = 0; i < 15; i++) begin
        assign bt_init_addr_in[i+1] = bt_init_addr_out[i];
    end
    
    assign bt_init_addr_in[0] = addr[0] ? 2 : 1;

    // max_match
    logic [15:0][7:0] bt_max_match_in;
    logic [15:0][7:0] bt_max_match_out;

    for (genvar i = 0; i < 15; i++) begin
        assign bt_max_match_in[i+1] = bt_max_match_out[i];
    end

    assign bt_max_match_in[0] = 0;

    // prefix
    logic [15:0][127:0] bt_prefix_in;
    logic [15:0][127:0] bt_prefix_out;

    for (genvar i = 0; i < 15; i++) begin
        assign bt_prefix_in[i+1] = bt_prefix_out[i];
    end

    assign bt_prefix_in[0] = addr;

    // next_hop
    logic [15:0][4:0] bt_next_hop_in;
    logic [15:0][4:0] bt_next_hop_out;

    for (genvar i = 0; i < 15; i++) begin
        assign bt_next_hop_in[i+1] = bt_next_hop_out[i];
    end

    assign bt_next_hop_in[0] = default_next_hop;


    assign next_hop = vc_max_match_out[15] >= bt_max_match_out[15] ? vc_next_hop_out[15] : bt_next_hop_out[15];

    for (genvar i = 0; i < 16; i++) begin: g_tries
        trie8 #(
            .VC_ADDR_WIDTH(VC_ADDR_WIDTH[i]),
            .VC_BIN_SIZE(VC_BIN_SIZE[i]),
            .BEGIN_LEVEL(i * 8)
        ) t(
            .clk(clk),
            .rst_p(rst_p),
            .frame_beat_i(frame_beat_in[i]),
            .in_valid(trie_in_valid[i]),
            .out_ready(trie_out_ready[i]),
            .frame_beat_o(frame_beat_out[i]),
            .in_ready(trie_in_ready[i]),
            .out_valid(trie_out_valid[i]),
            .vc_addr_o(vc_addr[i][VC_ADDR_WIDTH[i]-1:0]),
            .vc_node_i(vc_node[i][VC_NODE_WIDTH[i]-1:0]),
            .vc_init_addr_i(vc_init_addr_in[i][VC_ADDR_WIDTH[i]-1:0]),
            .vc_max_match_i(vc_max_match_in[i]),
            .vc_remaining_prefix_i(vc_prefix_in[i]),
            .vc_next_hop_offset_i(vc_next_hop_in[i]),
            .vc_init_addr_o(vc_init_addr_out[i][VC_ADDR_WIDTH[i]-1:0]),
            .vc_max_match_o(vc_max_match_out[i]),
            .vc_remaining_prefix_o(vc_prefix_out[i]),
            .vc_next_hop_offset_o(vc_next_hop_out[i]),
            .bt_addr_o(bt_addr[i]),
            .bt_node_i(bt_node[i]),
            .bt_init_addr_i(bt_init_addr_in[i]),
            .bt_max_match_i(bt_max_match_in[i]),
            .bt_remaining_prefix_i(bt_prefix_in[i]),
            .bt_next_hop_offset_i(bt_next_hop_in[i]),
            .bt_init_addr_o(bt_init_addr_out[i]),
            .bt_max_match_o(bt_max_match_out[i]),
            .bt_remaining_prefix_o(bt_prefix_out[i]),
            .bt_next_hop_offset_o(bt_next_hop_out[i])
        );
    end

    for (genvar i = 0; i < 16; i++) begin : g_bt_brams
        blk_mem_bt bt_bram_i (
            .clka (clk),        // input wire clka
            .ena  (1'b1),       // input wire ena
            .wea  (1'b0),       // input wire [0 : 0] wea
            .addra(bt_addr[i]), // input wire [12 : 0] addra
            .dina (0),          // input wire [35 : 0] dina
            .douta(bt_node[i]), // output reg [35 : 0] douta
            .clkb (clk),        // input wire clkb
            .enb  (1'b1),       // input wire enb
            .web  (1'b0),       // input wire [0 : 0] web
            .addrb(1'b0),       // input wire [12 : 0] addrb
            .dinb (0),          // input wire [35 : 0] dinb
            .doutb()            // output reg [35 : 0] doutb
        );
    end

    blk_mem_vc_0_def vc_bram_0 (
            .clka (clk),        // input wire clka
            .ena  (1'b1),       // input wire ena
            .wea  (1'b0),       // input wire [0 : 0] wea
            .addra(vc_addr[0][VC_ADDR_WIDTH[0]-1:0]), // input wire [7 : 0] addra
            .dina (0),          // input wire [53 : 0] dina
            .douta(vc_node[0][VC_NODE_WIDTH[0]-1:0]), // output reg [53 : 0] douta
            .clkb (clk),        // input wire clkb
            .enb  (1'b1),       // input wire enb
            .web  (1'b0),       // input wire [0 : 0] web
            .addrb(1'b0),       // input wire [7 : 0] addrb
            .dinb (0),          // input wire [53 : 0] dinb
            .doutb()            // output reg [53 : 0] doutb
    );

    blk_mem_vc_1 vc_bram_1 (
            .clka (clk),        // input wire clka
            .ena  (1'b1),       // input wire ena
            .wea  (1'b0),       // input wire [0 : 0] wea
            .addra(vc_addr[1][VC_ADDR_WIDTH[1]-1:0]), // input wire [12 : 0] addra
            .dina (0),          // input wire [305 : 0] dina
            .douta(vc_node[1][VC_NODE_WIDTH[1]-1:0]), // output reg [305 : 0] douta
            .clkb (clk),        // input wire clkb
            .enb  (1'b1),       // input wire enb
            .web  (1'b0),       // input wire [0 : 0] web
            .addrb(1'b0),       // input wire [12 : 0] addrb
            .dinb (0),          // input wire [305 : 0] dinb
            .doutb()            // output reg [305 : 0] doutb
    );

    blk_mem_vc_2 vc_bram_2 (
            .clka (clk),        // input wire clka
            .ena  (1'b1),       // input wire ena
            .wea  (1'b0),       // input wire [0 : 0] wea
            .addra(vc_addr[2][VC_ADDR_WIDTH[2]-1:0]), // input wire [12 : 0] addra
            .dina (0),          // input wire [611 : 0] dina
            .douta(vc_node[2][VC_NODE_WIDTH[2]-1:0]), // output reg [611 : 0] douta
            .clkb (clk),        // input wire clkb
            .enb  (1'b1),       // input wire enb
            .web  (1'b0),       // input wire [0 : 0] web
            .addrb(1'b0),       // input wire [12 : 0] addrb
            .dinb (0),          // input wire [611 : 0] dinb
            .doutb()            // output reg [611 : 0] doutb
    );

    blk_mem_vc_3 vc_bram_3 (
            .clka (clk),        // input wire clka
            .ena  (1'b1),       // input wire ena
            .wea  (1'b0),       // input wire [0 : 0] wea
            .addra(vc_addr[3][VC_ADDR_WIDTH[3]-1:0]), // input wire [12 : 0] addra
            .dina (0),          // input wire [611 : 0] dina
            .douta(vc_node[3][VC_NODE_WIDTH[3]-1:0]), // output reg [611 : 0] douta
            .clkb (clk),        // input wire clkb
            .enb  (1'b1),       // input wire enb
            .web  (1'b0),       // input wire [0 : 0] web
            .addrb(1'b0),       // input wire [12 : 0] addrb
            .dinb (0),          // input wire [611 : 0] dinb
            .doutb()            // output reg [611 : 0] doutb
    );

    blk_mem_vc_4 vc_bram_4 (
            .clka (clk),        // input wire clka
            .ena  (1'b1),       // input wire ena
            .wea  (1'b0),       // input wire [0 : 0] wea
            .addra(vc_addr[4][VC_ADDR_WIDTH[4]-1:0]), // input wire [12 : 0] addra
            .dina (0),          // input wire [557 : 0] dina
            .douta(vc_node[4][VC_NODE_WIDTH[4]-1:0]), // output reg [557 : 0] douta
            .clkb (clk),        // input wire clkb
            .enb  (1'b1),       // input wire enb
            .web  (1'b0),       // input wire [0 : 0] web
            .addrb(1'b0),       // input wire [12 : 0] addrb
            .dinb (0),          // input wire [557 : 0] dinb
            .doutb()            // output reg [557 : 0] doutb
    );

    blk_mem_vc_5 vc_bram_5 (
            .clka (clk),        // input wire clka
            .ena  (1'b1),       // input wire ena
            .wea  (1'b0),       // input wire [0 : 0] wea
            .addra(vc_addr[5][VC_ADDR_WIDTH[5]-1:0]), // input wire [11 : 0] addra
            .dina (0),          // input wire [413 : 0] dina
            .douta(vc_node[5][VC_NODE_WIDTH[5]-1:0]), // output reg [413 : 0] douta
            .clkb (clk),        // input wire clkb
            .enb  (1'b1),       // input wire enb
            .web  (1'b0),       // input wire [0 : 0] web
            .addrb(1'b0),       // input wire [11 : 0] addrb
            .dinb (0),          // input wire [413 : 0] dinb
            .doutb()            // output reg [413 : 0] doutb
    );

    for (genvar i = 6; i < 16; i = i + 1) begin: vc_bram_def
        blk_mem_vc_0_def vc_bram_6tof (
            .clka (clk),        // input wire clka
            .ena  (1'b1),       // input wire ena
            .wea  (1'b0),       // input wire [0 : 0] wea
            .addra(vc_addr[i][VC_ADDR_WIDTH[i]-1:0]), // input wire [7 : 0] addra
            .dina (0),          // input wire [53 : 0] dina
            .douta(vc_node[i][VC_NODE_WIDTH[i]-1:0]), // output reg [53 : 0] douta
            .clkb (clk),        // input wire clkb
            .enb  (1'b1),       // input wire enb
            .web  (1'b0),       // input wire [0 : 0] web
            .addrb(1'b0),       // input wire [7 : 0] addrb
            .dinb (0),          // input wire [53 : 0] dinb
            .doutb()            // output reg [53 : 0] doutb
        );
    end

endmodule
