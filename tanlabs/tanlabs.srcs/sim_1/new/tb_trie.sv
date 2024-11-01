`timescale 1ns / 1ps

module tb_trie;

	wire clk;
	reg  rst_p;

	clock clock_i(
        .clk_125M(clk)
    );

    initial begin
    	rst_p = 1;
    	#1000
    	rst_p = 0;
    end

    reg [127:0] default_route;
    reg [  4:0] default_next_hop_offset;
    frame_beat  beat;
    reg [127:0] ip_addr;

    logic [ 7:0] addr_0;
    logic [ 7:0] addr_1;
    logic [13:0] addr_2;
    logic [13:0] addr_3;
    logic [13:0] addr_4;
    logic [13:0] addr_5;
    logic [12:0] addr_6;
    logic [12:0] addr_7;
    logic [12:0] addr_8;
    logic [12:0] addr_9;
    logic [12:0] addr_10;
    logic [12:0] addr_11;
    logic [12:0] addr_12;
    logic [12:0] addr_13;
    logic [12:0] addr_14;
    logic [12:0] addr_15;

    logic [ 53:0] data_0;
    logic [593:0] data_1;
    logic [611:0] data_2;
    logic [611:0] data_3;
    logic [611:0] data_4;
    logic [449:0] data_5;
    logic [215:0] data_6;
    logic [215:0] data_7;
    logic [215:0] data_8;
    logic [215:0] data_9;
    logic [215:0] data_10;
    logic [215:0] data_11;
    logic [215:0] data_12;
    logic [215:0] data_13;
    logic [215:0] data_14;
    logic [215:0] data_15;

    logic [127:0] ip_addr_0;
    logic [127:0] ip_addr_1;
    logic [127:0] ip_addr_2;
    logic [127:0] ip_addr_3;
    logic [127:0] ip_addr_4;
    logic [127:0] ip_addr_5;
    logic [127:0] ip_addr_6;
    logic [127:0] ip_addr_7;
    logic [127:0] ip_addr_8;
    logic [127:0] ip_addr_9;
    logic [127:0] ip_addr_10;
    logic [127:0] ip_addr_11;
    logic [127:0] ip_addr_12;
    logic [127:0] ip_addr_13;
    logic [127:0] ip_addr_14;
    logic [127:0] ip_addr_15;

    logic [4:0] offset_0;
    logic [4:0] offset_1;
    logic [4:0] offset_2;
    logic [4:0] offset_3;
    logic [4:0] offset_4;
    logic [4:0] offset_5;
    logic [4:0] offset_6;
    logic [4:0] offset_7;
    logic [4:0] offset_8;
    logic [4:0] offset_9;
    logic [4:0] offset_10;
    logic [4:0] offset_11;
    logic [4:0] offset_12;
    logic [4:0] offset_13;
    logic [4:0] offset_14;
    logic [4:0] offset_15;

    logic valid_0;
    logic valid_1;
    logic valid_2;
    logic valid_3;
    logic valid_4;
    logic valid_5;
    logic valid_6;
    logic valid_7;
    logic valid_8;
    logic valid_9;
    logic valid_10;
    logic valid_11;
    logic valid_12;
    logic valid_13;
    logic valid_14;
    logic valid_15;

    logic ready_0;
    logic ready_1;
    logic ready_2;
    logic ready_3;
    logic ready_4;
    logic ready_5;
    logic ready_6;
    logic ready_7;
    logic ready_8;
    logic ready_9;
    logic ready_10;
    logic ready_11;
    logic ready_12;
    logic ready_13;
    logic ready_14;
    logic ready_15;

    logic skip_0;
    logic skip_1;
    logic skip_2;
    logic skip_3;
    logic skip_4;
    logic skip_5;
    logic skip_6;
    logic skip_7;
    logic skip_8;
    logic skip_9;
    logic skip_10;
    logic skip_11;
    logic skip_12;
    logic skip_13;
    logic skip_14;
    logic skip_15;

    frame_beat frame_beat_0;
    frame_beat frame_beat_1;
    frame_beat frame_beat_2;
    frame_beat frame_beat_3;
    frame_beat frame_beat_4;
    frame_beat frame_beat_5;
    frame_beat frame_beat_6;
    frame_beat frame_beat_7;
    frame_beat frame_beat_8;
    frame_beat frame_beat_9;
    frame_beat frame_beat_10;
    frame_beat frame_beat_11;
    frame_beat frame_beat_12;
    frame_beat frame_beat_13;
    frame_beat frame_beat_14;
    frame_beat frame_beat_15;

    blk_mem_gen_0 bram_0(
        .addra(addr_0),
        .clka(clk),
        .dina(),
        .douta(data_0),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_1 bram_1(
        .addra(addr_1),
        .clka(clk),
        .dina(),
        .douta(data_1),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_2 bram_2(
        .addra(addr_2),
        .clka(clk),
        .dina(),
        .douta(data_2),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_3 bram_3(
        .addra(addr_3),
        .clka(clk),
        .dina(),
        .douta(data_3),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_4 bram_4(
        .addra(addr_4),
        .clka(clk),
        .dina(),
        .douta(data_4),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_5 bram_5(
        .addra(addr_5),
        .clka(clk),
        .dina(),
        .douta(data_5),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_6 bram_6(
        .addra(addr_6),
        .clka(clk),
        .dina(),
        .douta(data_6),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_7 bram_7(
        .addra(addr_7),
        .clka(clk),
        .dina(),
        .douta(data_7),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_8 bram_8(
        .addra(addr_8),
        .clka(clk),
        .dina(),
        .douta(data_8),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_9 bram_9(
        .addra(addr_9),
        .clka(clk),
        .dina(),
        .douta(data_9),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_10 bram_10(
        .addra(addr_10),
        .clka(clk),
        .dina(),
        .douta(data_10),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_11 bram_11(
        .addra(addr_11),
        .clka(clk),
        .dina(),
        .douta(data_11),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_12 bram_12(
        .addra(addr_12),
        .clka(clk),
        .dina(),
        .douta(data_12),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_13 bram_13(
        .addra(addr_13),
        .clka(clk),
        .dina(),
        .douta(data_13),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_14 bram_14(
        .addra(addr_14),
        .clka(clk),
        .dina(),
        .douta(data_14),
        .ena(1'b1),
        .wea(1'b0)
    );

    blk_mem_gen_15 bram_15(
        .addra(addr_15),
        .clka(clk),
        .dina(),
        .douta(data_15),
        .ena(1'b1),
        .wea(1'b0)
    );

    trie_lookup #(
    	.width(54),
    	.depth(256),
    	.bin_size(1),
    	.addr_width(8),
    	.begin_level(0)
    ) trie_0 (
    	.clk(clk),
    	.rst_p(rst_p),
    	.node(data_0),
    	.init_addr(),
    	.max_match_i(8'd0),
    	.prefix_i(ip_addr),
    	.next_hop_offset_i(default_next_hop_offset),
    	.frame_beat_i(beat),
    	.valid_i(1'b1),
    	.skip_i(1'b0),
    	.ready_o(ready_0),
    	.ready_i(ready_1),
    	.prefix_o(ip_addr_0),
    	.next_hop_offset_o(offset_0),
    	.frame_beat_o(frame_beat_0),
    	.valid_o(valid_0),
    	.skip_o(skip_0),
    	.addr(addr_0),
    	.next_addr_o(),
    	.max_match_o(),
    	.rea_o()
    );

endmodule
