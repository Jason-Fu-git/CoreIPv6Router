`timescale 1ns / 1ps
`include "frame_datapath.vh"


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
    output reg [  4:0] next_hop,

    // Wishbone signals
    input wire cpu_clk,
    input wire cpu_rst_p,
    input wire [31:0] cpu_adr_raw,
    input wire [31:0] cpu_dat_in_raw,
    output reg [31:0] cpu_dat_out_raw,
    input wire cpu_wea_raw,
    input wire cpu_stb_raw,
    output reg cpu_ack_raw
);

    logic [31:0] cpu_adr, cpu_dat_in, cpu_dat_out;
    logic cpu_wea, cpu_stb, cpu_ack;
    logic cpu_read_valid, cpu_write_valid, bram_read_valid, bram_write_valid;

    parameter int VC_ADDR_WIDTH [0:16] = {8, 13, 13, 13, 13, 12, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0};
    parameter int VC_SIZE_WIDTH [0:15] = {6, 8, 13, 13, 13, 12, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8};
    parameter int VC_BIN_SIZE   [0:15] = {1, 7,  15, 15, 14, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};
    parameter int VC_NODE_WIDTH [0:15] = {54,306,612,612,558,414,54,54,54,54,54,54,54,54,54,54};
    parameter MAX_VC_ADDR_WIDTH        = 13;
    parameter MAX_VC_NODE_WIDTH        = 612;
    parameter BT_ADDR_WIDTH            = 13;
    parameter BT_NODE_WIDTH            = 36;

    parameter LEVELS = 16;
    parameter BT_LEVELS = 8;

    // frame_beat
    frame_beat [LEVELS-1:0] frame_beat_in;
    frame_beat [LEVELS-1:0] frame_beat_out;

    always_comb begin
        for (int i = 0; i < LEVELS - 1; i = i + 1) begin
            frame_beat_in[i+1] = frame_beat_out[i];
        end
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
        out.data = frame_beat_out[LEVELS-1];
        out.data.data.ip6.dst = next_hop_ip6;
        out.data.meta.dest = next_hop_iface;
    end

    // valid, ready
    logic [LEVELS-1:0] trie_in_valid;
    logic [LEVELS-1:0] trie_out_valid;
    logic [LEVELS-1:0] trie_in_ready;
    logic [LEVELS-1:0] trie_out_ready;

    always_comb begin
        for (int i = 0; i < LEVELS-1; i = i + 1) begin
            trie_in_valid[i+1] = trie_out_valid[i];
            trie_out_ready[i]  = trie_in_ready[i+1];
        end
    end

    assign trie_in_valid[0]   = in_valid;
    assign out_valid          = trie_out_valid[LEVELS-1];
    assign trie_out_ready[LEVELS-1] = out_ready;
    assign in_ready           = trie_in_ready[0];

    // VCTrie

    // node, addr
    logic [LEVELS-1:0][MAX_VC_ADDR_WIDTH-1:0] vc_addr;
    logic [LEVELS-1:0][MAX_VC_NODE_WIDTH-1:0] vc_node;

    logic [LEVELS-1:0][MAX_VC_ADDR_WIDTH-1:0] vc_init_addr_in;
    logic [LEVELS-1:0][MAX_VC_ADDR_WIDTH-1:0] vc_init_addr_out;

    always_comb begin
        for (int i = 0; i < LEVELS-1; i = i + 1) begin
            vc_init_addr_in[i+1] = vc_init_addr_out[i];
        end
    end

    assign vc_init_addr_in[0] = addr[0] ? 2 : 1;

    // max_match
    logic [LEVELS-1:0][7:0] vc_max_match_in;
    logic [LEVELS-1:0][7:0] vc_max_match_out;

    always_comb begin
        for (int i = 0; i < LEVELS-1; i = i + 1) begin
            vc_max_match_in[i+1] = vc_max_match_out[i+1];
        end
    end

    assign vc_max_match_in[0] = 0;

    // prefix
    logic [LEVELS-1:0][127:0] vc_prefix_in;
    logic [LEVELS-1:0][127:0] vc_prefix_out;

    always_comb begin
        for (int i = 0; i < LEVELS-1; i = i + 1) begin
            vc_prefix_in[i+1] = vc_prefix_out[i];
        end
    end

    assign vc_prefix_in[0] = addr;

    // next_hop
    logic [LEVELS-1:0][4:0] vc_next_hop_in;
    logic [LEVELS-1:0][4:0] vc_next_hop_out;

    always_comb begin
        for (int i = 0; i < LEVELS-1; i = i + 1) begin
            vc_next_hop_in[i+1] = vc_next_hop_out[i];
        end
    end

    assign vc_next_hop_in[0] = default_next_hop;

    // BTrie

    // node, addr
    logic [LEVELS-1:0][BT_ADDR_WIDTH-1:0] bt_addr;
    logic [LEVELS-1:0][BT_NODE_WIDTH-1:0] bt_node;

    logic [LEVELS-1:0][BT_ADDR_WIDTH-1:0] bt_init_addr_in;
    logic [LEVELS-1:0][BT_ADDR_WIDTH-1:0] bt_init_addr_out;

    always_comb begin
        for (int i = 0; i < LEVELS-1; i = i + 1) begin
            bt_init_addr_in[i+1] = bt_init_addr_out[i];
        end
    end
    
    assign bt_init_addr_in[0] = addr[0] ? 2 : 1;

    // max_match
    logic [LEVELS-1:0][7:0] bt_max_match_in;
    logic [LEVELS-1:0][7:0] bt_max_match_out;

    always_comb begin
        for (int i = 0; i < LEVELS-1; i = i + 1) begin
            bt_max_match_in[i+1] = bt_max_match_out[i];
        end
    end

    assign bt_max_match_in[0] = 0;

    // prefix
    logic [LEVELS-1:0][127:0] bt_prefix_in;
    logic [LEVELS-1:0][127:0] bt_prefix_out;

    always_comb begin
        for (int i = 0; i < LEVELS-1; i = i + 1) begin
            bt_prefix_in[i+1] = bt_prefix_out[i];
        end
    end

    assign bt_prefix_in[0] = addr;

    // next_hop
    logic [LEVELS-1:0][4:0] bt_next_hop_in;
    logic [LEVELS-1:0][4:0] bt_next_hop_out;

    always_comb begin
        for (int i = 0; i < LEVELS-1; i = i + 1) begin
            bt_next_hop_in[i+1] = bt_next_hop_out[i];
        end
    end

    assign bt_next_hop_in[0] = default_next_hop;


    assign next_hop = vc_max_match_out[LEVELS-1] >= bt_max_match_out[LEVELS-1] ? vc_next_hop_out[LEVELS-1] : bt_next_hop_out[LEVELS-1];

    logic [LEVELS-1:0][BT_NODE_WIDTH-1:0] cpu_bt_node;
    logic [LEVELS-1:0][MAX_VC_NODE_WIDTH-1:0] cpu_vc_node;
    logic [LEVELS-1:0][BT_NODE_WIDTH-1:0] cpu_bt_node_in;
    logic [LEVELS-1:0][MAX_VC_NODE_WIDTH-1:0] cpu_vc_node_in;
    logic [LEVELS-1:0] cpu_bt_node_wea;
    logic [LEVELS-1:0] cpu_vc_node_wea;
    logic [LEVELS-1:0][BT_ADDR_WIDTH-1:0] cpu_bt_addr;
    logic [LEVELS-1:0][MAX_VC_ADDR_WIDTH-1:0] cpu_vc_addr;

    generate
        for (genvar i = 0; i < LEVELS; i++) begin: g_tries
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
    endgenerate

    logic [LEVELS-1:0] bt_bram_write_stb;
    logic [LEVELS-1:0][31:0] bt_wbs_dat_out;
    logic [LEVELS-1:0][31:0] vc_wbs_dat_out;
    logic [LEVELS-1:0][1:0] bt_wbs_ack_state;
    logic [LEVELS-1:0][1:0] vc_wbs_ack_state;
    logic [LEVELS-1:0] bt_wbs_ack;
    logic [LEVELS-1:0] vc_wbs_ack;

    always_comb begin
        for (int i = 0; i < LEVELS; i = i + 1) begin
            cpu_bt_node_wea[i] = bt_bram_write_stb[i];
            cpu_bt_addr[i] = cpu_adr[22:10];
        end
    end

    generate
        for (genvar i = 0; i < BT_LEVELS; i = i + 1) begin : g_bt_brams
            blk_mem_bt bt_bram_i (
                .clka (clk),        // input wire clka
                .ena  (1'b1),       // input wire ena
                .wea  (1'b0),       // input wire [0 : 0] wea
                .addra(bt_addr[i]), // input wire [12 : 0] addra
                .dina (0),          // input wire [35 : 0] dina
                .douta(bt_node[i]), // output reg [35 : 0] douta
                .clkb (clk),        // input wire clkb
                .enb  (1'b1),       // input wire enb
                .web  (cpu_bt_node_wea[i]),       // input wire [0 : 0] web
                .addrb(cpu_bt_addr[i]),       // input wire [12 : 0] addrb
                .dinb (cpu_bt_node_in[i]),          // input wire [35 : 0] dinb
                .doutb(cpu_bt_node[i])            // output reg [35 : 0] doutb
            );
            bram_data_converter_bt bram_data_converter_bt_i(
                .in(cpu_bt_node[i]),
                .out(bt_wbs_dat_out[i]),
                .cpu_write_in(cpu_dat_in),
                .cpu_write_out(cpu_bt_node_in[i])
            );
        end
    endgenerate

    always_comb begin
        for (int i = BT_LEVELS; i < LEVELS; i = i + 1) begin
            bt_node[i] = 0;
            cpu_bt_node[i] = 0;
        end
    end

    logic [LEVELS-1:0][MAX_VC_NODE_WIDTH-1:0] cpu_vc_node_buffer;
    logic [LEVELS-1:0] vc_bram_buffer_stb;

    always_comb begin
        for (int i = 0; i < LEVELS; i = i + 1) begin
            cpu_vc_node_in[i] = cpu_vc_node_buffer[i];
            cpu_vc_addr[i] = cpu_adr[22:10];
            cpu_vc_node_wea[i] = vc_bram_buffer_stb[i];
        end
    end

    always_ff @(posedge clk) begin
        if (rst_p) begin
            bt_wbs_ack_state <= 0;
            vc_wbs_ack_state <= 0;
        end else begin
            for (int i = 0; i < LEVELS; i = i + 1) begin
                if ((bt_wbs_ack_state[i] == 2'b00) && bt_bram_write_stb[i]) begin
                    bt_wbs_ack_state[i] <= 2'b01;  // STATE WAIT
                end else if (bt_wbs_ack_state[i] == 2'b01) begin
                    bt_wbs_ack_state[i] <= 2'b11;  // STATE DONE
                end else begin
                    bt_wbs_ack_state[i] <= 2'b00;  // STATE IDLE
                end
                if ((vc_wbs_ack_state[i] == 2'b00) && vc_bram_buffer_stb[i]) begin
                    vc_wbs_ack_state[i] <= 2'b01;  // STATE WAIT
                end else if (vc_wbs_ack_state[i] == 2'b01) begin
                    vc_wbs_ack_state[i] <= 2'b11;  // STATE DONE
                end else begin
                    vc_wbs_ack_state[i] <= 2'b00;  // STATE IDLE
                end
            end
        end
    end

    always_comb begin
        for (int i = 0; i < LEVELS; i = i + 1) begin
            bt_wbs_ack[i] = (bt_wbs_ack_state[i] == 2'b11);
            vc_wbs_ack[i] = (vc_wbs_ack_state[i] == 2'b11);
        end
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
            .web  (cpu_vc_node_wea[0]),       // input wire [0 : 0] web
            .addrb(cpu_vc_addr[0][VC_ADDR_WIDTH[0]-1:0]),       // input wire [7 : 0] addrb
            .dinb (cpu_vc_node_in[0][VC_NODE_WIDTH[0]-1:0]),          // input wire [53 : 0] dinb
            .doutb(cpu_vc_node[0][VC_NODE_WIDTH[0]-1:0])            // output reg [53 : 0] doutb
    );

    bram_buffer_1 vc_bram_buffer_0(
        .clk(clk),
        .rst_p(rst_p),
        .dat_in(cpu_dat_in),
        .sel(cpu_adr[9:2]),
        .stb(vc_bram_buffer_stb[0]),
        .node_in(cpu_vc_node[0][VC_NODE_WIDTH[0]-1:0]),
        .buffer(cpu_vc_node_buffer[0][VC_NODE_WIDTH[0]-1:0])
    );
    bram_data_converter_1 bram_data_converter_i_0(
        .in(cpu_vc_node[0][VC_NODE_WIDTH[0]-1:0]),
        .sel(cpu_adr[9:2]),
        .out(vc_wbs_dat_out[0])
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
            .web  (cpu_vc_node_wea[1]),                      // input wire [0 : 0] web
            .addrb(cpu_vc_addr[1][VC_ADDR_WIDTH[1]-1:0]),    // input wire [12 : 0] addrb
            .dinb (cpu_vc_node_in[1][VC_NODE_WIDTH[1]-1:0]), // input wire [305 : 0] dinb
            .doutb(cpu_vc_node[1][VC_NODE_WIDTH[1]-1:0])     // output reg [305 : 0] doutb
    );

    bram_buffer_7 vc_bram_buffer_1(
        .clk(clk),
        .rst_p(rst_p),
        .dat_in(cpu_dat_in),
        .sel(cpu_adr[9:2]),
        .stb(vc_bram_buffer_stb[1]),
        .node_in(cpu_vc_node[1][VC_NODE_WIDTH[1]-1:0]),
        .buffer(cpu_vc_node_buffer[1][VC_NODE_WIDTH[1]-1:0])
    );
    bram_data_converter_7 bram_data_converter_i_1(
        .in(cpu_vc_node[1][VC_NODE_WIDTH[1]-1:0]),
        .sel(cpu_adr[9:2]),
        .out(vc_wbs_dat_out[1])
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
            .web  (cpu_vc_node_wea[2]),                      // input wire [0 : 0] web
            .addrb(cpu_vc_addr[2][VC_ADDR_WIDTH[2]-1:0]),    // input wire [12 : 0] addrb
            .dinb (cpu_vc_node_in[2][VC_NODE_WIDTH[2]-1:0]), // input wire [611 : 0] dinb
            .doutb(cpu_vc_node[2][VC_NODE_WIDTH[2]-1:0])     // output reg [611 : 0] doutb
    );

    bram_buffer_15 vc_bram_buffer_2(
        .clk(clk),
        .rst_p(rst_p),
        .dat_in(cpu_dat_in),
        .sel(cpu_adr[9:2]),
        .stb(vc_bram_buffer_stb[2]),
        .node_in(cpu_vc_node[2][VC_NODE_WIDTH[2]-1:0]),
        .buffer(cpu_vc_node_buffer[2][VC_NODE_WIDTH[2]-1:0])
    );
    bram_data_converter_15 bram_data_converter_i_2(
        .in(cpu_vc_node[2][VC_NODE_WIDTH[2]-1:0]),
        .sel(cpu_adr[9:2]),
        .out(vc_wbs_dat_out[2])
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
            .web  (cpu_vc_node_wea[3]),                      // input wire [0 : 0] web
            .addrb(cpu_vc_addr[3][VC_ADDR_WIDTH[3]-1:0]),    // input wire [12 : 0] addrb
            .dinb (cpu_vc_node_in[3][VC_NODE_WIDTH[3]-1:0]), // input wire [611 : 0] dinb
            .doutb(cpu_vc_node[3][VC_NODE_WIDTH[3]-1:0])     // output reg [611 : 0] doutb
    );
    bram_buffer_15 vc_bram_buffer_3(
        .clk(clk),
        .rst_p(rst_p),
        .dat_in(cpu_dat_in),
        .sel(cpu_adr[9:2]),
        .stb(vc_bram_buffer_stb[3]),
        .node_in(cpu_vc_node[3][VC_NODE_WIDTH[3]-1:0]),
        .buffer(cpu_vc_node_buffer[3][VC_NODE_WIDTH[3]-1:0])
    );
    bram_data_converter_15 bram_data_converter_i_3(
        .in(cpu_vc_node[3][VC_NODE_WIDTH[3]-1:0]),
        .sel(cpu_adr[9:2]),
        .out(vc_wbs_dat_out[3])
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
            .web  (cpu_vc_node_wea[4]),                      // input wire [0 : 0] web
            .addrb(cpu_vc_addr[4][VC_ADDR_WIDTH[4]-1:0]),    // input wire [12 : 0] addrb
            .dinb (cpu_vc_node_in[4][VC_NODE_WIDTH[4]-1:0]), // input wire [557 : 0] dinb
            .doutb(cpu_vc_node[4][VC_NODE_WIDTH[4]-1:0])     // output reg [557 : 0] doutb
    );

    bram_buffer_14 vc_bram_buffer_4(
        .clk(clk),
        .rst_p(rst_p),
        .dat_in(cpu_dat_in),
        .sel(cpu_adr[9:2]),
        .stb(vc_bram_buffer_stb[4]),
        .node_in(cpu_vc_node[4][VC_NODE_WIDTH[4]-1:0]),
        .buffer(cpu_vc_node_buffer[4][VC_NODE_WIDTH[4]-1:0])
    );
    bram_data_converter_14 bram_data_converter_i_4(
        .in(cpu_vc_node[4][VC_NODE_WIDTH[4]-1:0]),
        .sel(cpu_adr[9:2]),
        .out(vc_wbs_dat_out[4])
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
            .web  (cpu_vc_node_wea[5]),                      // input wire [0 : 0] web
            .addrb(cpu_vc_addr[5][VC_ADDR_WIDTH[5]-1:0]),    // input wire [11 : 0] addrb
            .dinb (cpu_vc_node_in[5][VC_NODE_WIDTH[5]-1:0]), // input wire [413 : 0] dinb
            .doutb(cpu_vc_node[5][VC_NODE_WIDTH[5]-1:0])     // output reg [413 : 0] doutb
    );

    bram_buffer_10 vc_bram_buffer_5(
        .clk(clk),
        .rst_p(rst_p),
        .dat_in(cpu_dat_in),
        .sel(cpu_adr[9:2]),
        .stb(vc_bram_buffer_stb[5]),
        .node_in(cpu_vc_node[5][VC_NODE_WIDTH[5]-1:0]),
        .buffer(cpu_vc_node_buffer[5][VC_NODE_WIDTH[5]-1:0])
    );
    bram_data_converter_10 bram_data_converter_i_5(
        .in(cpu_vc_node[5][VC_NODE_WIDTH[5]-1:0]),
        .sel(cpu_adr[9:2]),
        .out(vc_wbs_dat_out[5])
    );

    generate
        for (genvar i = 6; i < LEVELS; i = i + 1) begin: vc_bram_def
            blk_mem_vc_0_def vc_bram_i (
                .clka (clk),        // input wire clka
                .ena  (1'b1),       // input wire ena
                .wea  (1'b0),       // input wire [0 : 0] wea
                .addra(vc_addr[i][VC_ADDR_WIDTH[i]-1:0]), // input wire [7 : 0] addra
                .dina (0),          // input wire [53 : 0] dina
                .douta(vc_node[i][VC_NODE_WIDTH[i]-1:0]), // output reg [53 : 0] douta
                .clkb (clk),        // input wire clkb
                .enb  (1'b1),       // input wire enb
                .web  (cpu_vc_node_wea[i]),                      // input wire [0 : 0] web
                .addrb(cpu_vc_addr[i][VC_ADDR_WIDTH[i]-1:0]),    // input wire [7 : 0] addrb
                .dinb (cpu_vc_node_in[i][VC_NODE_WIDTH[i]-1:0]), // input wire [53 : 0] dinb
                .doutb(cpu_vc_node[i][VC_NODE_WIDTH[i]-1:0])     // output reg [53 : 0] doutb
            );
            bram_buffer_1 vc_bram_buffer_i(
                .clk(clk),
                .rst_p(rst_p),
                .dat_in(cpu_dat_in),
                .sel(cpu_adr[9:2]),
                .stb(vc_bram_buffer_stb[i]),
                .node_in(cpu_vc_node[i][VC_NODE_WIDTH[i]-1:0]),
                .buffer(cpu_vc_node_buffer[i][VC_NODE_WIDTH[i]-1:0])
            );
            bram_data_converter_1 bram_data_converter_i_i(
                .in(cpu_vc_node[i][VC_NODE_WIDTH[i]-1:0]),
                .sel(cpu_adr[9:2]),
                .out(vc_wbs_dat_out[i])
            );
        end
    endgenerate

    logic cpu_stb_trigger;
    logic cpu_stb_lock;
    logic bram_ack_trigger;
    logic bram_ack_lock;

    always_ff @(posedge cpu_clk) begin
        if (cpu_rst_p) begin
            cpu_stb_lock <= 0;
        end else begin
            cpu_stb_lock <= cpu_stb_raw;
        end
    end

    always_ff @(posedge clk) begin
        if (rst_p) begin
            bram_ack_lock <= 0;
        end else begin
            bram_ack_lock <= cpu_ack;
        end
    end

    assign cpu_stb_trigger = cpu_stb_raw && !cpu_stb_lock;
    assign cpu_write_valid = cpu_stb_trigger;
    assign bram_ack_trigger = cpu_ack && !bram_ack_lock;
    assign bram_read_valid = bram_ack_trigger;

    logic cpu_ack_delay;
    logic [31:0] cpu_dat_out_delay;
    logic cpu_stb_delay, cpu_wea_delay;
    logic [31:0] cpu_adr_delay, cpu_dat_in_delay;

    always_ff @(posedge clk) begin
        if (rst_p) begin
            cpu_ack_delay <= 0;
            cpu_dat_out_delay <= 0;
            cpu_stb <= 0;
            cpu_wea <= 0;
            cpu_adr <= 0;
            cpu_dat_in <= 0;
        end else begin
            cpu_ack_delay <= cpu_ack;
            cpu_dat_out_delay <= cpu_dat_out;
            cpu_stb <= cpu_stb_delay;
            cpu_wea <= cpu_wea_delay;
            cpu_adr <= cpu_adr_delay;
            cpu_dat_in <= cpu_dat_in_delay;
        end
    end

    axis_data_fifo_bram axis_data_fifo_bram_read_i(
        .s_axis_aclk(clk),
        .m_axis_aclk(cpu_clk),
        .s_axis_aresetn(~rst_p),

        .s_axis_tdata({cpu_ack_delay, cpu_dat_out_delay}),
        .s_axis_tready(), // NULL
        .s_axis_tvalid(bram_read_valid),
        .m_axis_tdata({cpu_ack_raw, cpu_dat_out_raw}),
        .m_axis_tready(1'b1),
        .m_axis_tvalid(cpu_read_valid)
    );

    axis_data_fifo_bram_cpu axis_data_fifo_bram_write_i(
        .s_axis_aclk(cpu_clk),
        .m_axis_aclk(clk),
        .s_axis_aresetn(~cpu_rst_p),

        .s_axis_tdata({cpu_stb_raw, cpu_wea_raw, cpu_adr_raw, cpu_dat_in_raw}),
        .s_axis_tready(), // NULL
        .s_axis_tvalid(cpu_write_valid),
        .m_axis_tdata({cpu_stb_delay, cpu_wea_delay, cpu_adr_delay, cpu_dat_in_delay}),
        .m_axis_tready(1'b1),
        .m_axis_tvalid(bram_write_valid)
    );

    bram_mux bram_mux_i(
        .clk(clk),
        .rst(rst_p),
        .wbm_adr_i(cpu_adr),
        .wbm_dat_i(cpu_dat_in),
        .wbm_dat_o(cpu_dat_out),
        .wbm_we_i(cpu_wea),
        .wbm_sel_i(4'b1111),  // Sent to converter, `sel` is of no use
        .wbm_stb_i(cpu_stb),
        .wbm_ack_o(cpu_ack),
        .wbm_err_o(),
        .wbm_rty_o(),
        .wbm_cyc_i(cpu_stb),
        .wbs0_addr(32'h20000000),
        .wbs0_addr_msk(32'hff800000),
        .wbs1_addr(32'h20800000),
        .wbs1_addr_msk(32'hff800000),
        .wbs2_addr(32'h21000000),
        .wbs2_addr_msk(32'hff800000),
        .wbs3_addr(32'h21800000),
        .wbs3_addr_msk(32'hff800000),
        .wbs4_addr(32'h22000000),
        .wbs4_addr_msk(32'hff800000),
        .wbs5_addr(32'h22800000),
        .wbs5_addr_msk(32'hff800000),
        .wbs6_addr(32'h23000000),
        .wbs6_addr_msk(32'hff800000),
        .wbs7_addr(32'h23800000),
        .wbs7_addr_msk(32'hff800000),
        .wbs8_addr(32'h24000000),
        .wbs8_addr_msk(32'hff800000),
        .wbs9_addr(32'h24800000),
        .wbs9_addr_msk(32'hff800000),
        .wbs10_addr(32'h25000000),
        .wbs10_addr_msk(32'hff800000),
        .wbs11_addr(32'h25800000),
        .wbs11_addr_msk(32'hff800000),
        .wbs12_addr(32'h26000000),
        .wbs12_addr_msk(32'hff800000),
        .wbs13_addr(32'h26800000),
        .wbs13_addr_msk(32'hff800000),
        .wbs14_addr(32'h27000000),
        .wbs14_addr_msk(32'hff800000),
        .wbs15_addr(32'h27800000),
        .wbs15_addr_msk(32'hff800000),
        .wbs16_addr(32'h28000000),
        .wbs16_addr_msk(32'hff800000),
        .wbs17_addr(32'h28800000),
        .wbs17_addr_msk(32'hff800000),
        .wbs18_addr(32'h29000000),
        .wbs18_addr_msk(32'hff800000),
        .wbs19_addr(32'h29800000),
        .wbs19_addr_msk(32'hff800000),
        .wbs20_addr(32'h2a000000),
        .wbs20_addr_msk(32'hff800000),
        .wbs21_addr(32'h2a800000),
        .wbs21_addr_msk(32'hff800000),
        .wbs22_addr(32'h2b000000),
        .wbs22_addr_msk(32'hff800000),
        .wbs23_addr(32'h2b800000),
        .wbs23_addr_msk(32'hff800000),
        .wbs24_addr(32'h2c000000),
        .wbs24_addr_msk(32'hff800000),
        .wbs25_addr(32'h2c800000),
        .wbs25_addr_msk(32'hff800000),
        .wbs26_addr(32'h2d000000),
        .wbs26_addr_msk(32'hff800000),
        .wbs27_addr(32'h2d800000),
        .wbs27_addr_msk(32'hff800000),
        .wbs28_addr(32'h2e000000),
        .wbs28_addr_msk(32'hff800000),
        .wbs29_addr(32'h2e800000),
        .wbs29_addr_msk(32'hff800000),
        .wbs30_addr(32'h2f000000),
        .wbs30_addr_msk(32'hff800000),
        .wbs31_addr(32'h2f800000),
        .wbs31_addr_msk(32'hff800000),
        .wbs0_stb_o(bt_bram_write_stb[0]),
        .wbs1_stb_o(bt_bram_write_stb[1]),
        .wbs2_stb_o(bt_bram_write_stb[2]),
        .wbs3_stb_o(bt_bram_write_stb[3]),
        .wbs4_stb_o(bt_bram_write_stb[4]),
        .wbs5_stb_o(bt_bram_write_stb[5]),
        .wbs6_stb_o(bt_bram_write_stb[6]),
        .wbs7_stb_o(bt_bram_write_stb[7]),
        .wbs8_stb_o(bt_bram_write_stb[8]),
        .wbs9_stb_o(bt_bram_write_stb[9]),
        .wbs10_stb_o(bt_bram_write_stb[10]),
        .wbs11_stb_o(bt_bram_write_stb[11]),
        .wbs12_stb_o(bt_bram_write_stb[12]),
        .wbs13_stb_o(bt_bram_write_stb[13]),
        .wbs14_stb_o(bt_bram_write_stb[14]),
        .wbs15_stb_o(bt_bram_write_stb[15]),
        .wbs16_stb_o(vc_bram_buffer_stb[0]),
        .wbs17_stb_o(vc_bram_buffer_stb[1]),
        .wbs18_stb_o(vc_bram_buffer_stb[2]),
        .wbs19_stb_o(vc_bram_buffer_stb[3]),
        .wbs20_stb_o(vc_bram_buffer_stb[4]),
        .wbs21_stb_o(vc_bram_buffer_stb[5]),
        .wbs22_stb_o(vc_bram_buffer_stb[6]),
        .wbs23_stb_o(vc_bram_buffer_stb[7]),
        .wbs24_stb_o(vc_bram_buffer_stb[8]),
        .wbs25_stb_o(vc_bram_buffer_stb[9]),
        .wbs26_stb_o(vc_bram_buffer_stb[10]),
        .wbs27_stb_o(vc_bram_buffer_stb[11]),
        .wbs28_stb_o(vc_bram_buffer_stb[12]),
        .wbs29_stb_o(vc_bram_buffer_stb[13]),
        .wbs30_stb_o(vc_bram_buffer_stb[14]),
        .wbs31_stb_o(vc_bram_buffer_stb[15]),
        .wbs0_dat_i(bt_wbs_dat_out[0]),
        .wbs1_dat_i(bt_wbs_dat_out[1]),
        .wbs2_dat_i(bt_wbs_dat_out[2]),
        .wbs3_dat_i(bt_wbs_dat_out[3]),
        .wbs4_dat_i(bt_wbs_dat_out[4]),
        .wbs5_dat_i(bt_wbs_dat_out[5]),
        .wbs6_dat_i(bt_wbs_dat_out[6]),
        .wbs7_dat_i(bt_wbs_dat_out[7]),
        .wbs8_dat_i(bt_wbs_dat_out[8]),
        .wbs9_dat_i(bt_wbs_dat_out[9]),
        .wbs10_dat_i(bt_wbs_dat_out[10]),
        .wbs11_dat_i(bt_wbs_dat_out[11]),
        .wbs12_dat_i(bt_wbs_dat_out[12]),
        .wbs13_dat_i(bt_wbs_dat_out[13]),
        .wbs14_dat_i(bt_wbs_dat_out[14]),
        .wbs15_dat_i(bt_wbs_dat_out[15]),
        .wbs16_dat_i(vc_wbs_dat_out[0]),
        .wbs17_dat_i(vc_wbs_dat_out[1]),
        .wbs18_dat_i(vc_wbs_dat_out[2]),
        .wbs19_dat_i(vc_wbs_dat_out[3]),
        .wbs20_dat_i(vc_wbs_dat_out[4]),
        .wbs21_dat_i(vc_wbs_dat_out[5]),
        .wbs22_dat_i(vc_wbs_dat_out[6]),
        .wbs23_dat_i(vc_wbs_dat_out[7]),
        .wbs24_dat_i(vc_wbs_dat_out[8]),
        .wbs25_dat_i(vc_wbs_dat_out[9]),
        .wbs26_dat_i(vc_wbs_dat_out[10]),
        .wbs27_dat_i(vc_wbs_dat_out[11]),
        .wbs28_dat_i(vc_wbs_dat_out[12]),
        .wbs29_dat_i(vc_wbs_dat_out[13]),
        .wbs30_dat_i(vc_wbs_dat_out[14]),
        .wbs31_dat_i(vc_wbs_dat_out[15]),
        .wbs0_ack_i(bt_wbs_ack[0]),
        .wbs1_ack_i(bt_wbs_ack[1]),
        .wbs2_ack_i(bt_wbs_ack[2]),
        .wbs3_ack_i(bt_wbs_ack[3]),
        .wbs4_ack_i(bt_wbs_ack[4]),
        .wbs5_ack_i(bt_wbs_ack[5]),
        .wbs6_ack_i(bt_wbs_ack[6]),
        .wbs7_ack_i(bt_wbs_ack[7]),
        .wbs8_ack_i(bt_wbs_ack[8]),
        .wbs9_ack_i(bt_wbs_ack[9]),
        .wbs10_ack_i(bt_wbs_ack[10]),
        .wbs11_ack_i(bt_wbs_ack[11]),
        .wbs12_ack_i(bt_wbs_ack[12]),
        .wbs13_ack_i(bt_wbs_ack[13]),
        .wbs14_ack_i(bt_wbs_ack[14]),
        .wbs15_ack_i(bt_wbs_ack[15]),
        .wbs16_ack_i(vc_wbs_ack[0]),
        .wbs17_ack_i(vc_wbs_ack[1]),
        .wbs18_ack_i(vc_wbs_ack[2]),
        .wbs19_ack_i(vc_wbs_ack[3]),
        .wbs20_ack_i(vc_wbs_ack[4]),
        .wbs21_ack_i(vc_wbs_ack[5]),
        .wbs22_ack_i(vc_wbs_ack[6]),
        .wbs23_ack_i(vc_wbs_ack[7]),
        .wbs24_ack_i(vc_wbs_ack[8]),
        .wbs25_ack_i(vc_wbs_ack[9]),
        .wbs26_ack_i(vc_wbs_ack[10]),
        .wbs27_ack_i(vc_wbs_ack[11]),
        .wbs28_ack_i(vc_wbs_ack[12]),
        .wbs29_ack_i(vc_wbs_ack[13]),
        .wbs30_ack_i(vc_wbs_ack[14]),
        .wbs31_ack_i(vc_wbs_ack[15])
    );

endmodule
