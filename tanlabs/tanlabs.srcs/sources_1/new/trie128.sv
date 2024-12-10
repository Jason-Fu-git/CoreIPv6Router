`timescale 1ns / 1ps

`include "trie.vh"

module trie128(
    input wire clk,
    input wire rst_p,
    input frame_beat in,
    output frame_beat out,
    input wire in_valid,
    input wire out_ready,
    output reg in_ready,
    output reg out_valid,
    input wire [  4:0] default_next_hop,
    input wire [127:0] addr,
    output reg [127:0] next_hop
);

    frame_beat t0_frame_beat_in, t1_frame_beat_in, t2_frame_beat_in, t3_frame_beat_in;
    frame_beat t4_frame_beat_in, t5_frame_beat_in, t6_frame_beat_in, t7_frame_beat_in;
    frame_beat t8_frame_beat_in, t9_frame_beat_in, ta_frame_beat_in, tb_frame_beat_in;
    frame_beat tc_frame_beat_in, td_frame_beat_in, te_frame_beat_in, tf_frame_beat_in;

    frame_beat t0_frame_beat_out, t1_frame_beat_out, t2_frame_beat_out, t3_frame_beat_out;
    frame_beat t4_frame_beat_out, t5_frame_beat_out, t6_frame_beat_out, t7_frame_beat_out;
    frame_beat t8_frame_beat_out, t9_frame_beat_out, ta_frame_beat_out, tb_frame_beat_out;
    frame_beat tc_frame_beat_out, td_frame_beat_out, te_frame_beat_out, tf_frame_beat_out;

    assign t0_frame_beat_in = in;
    assign t1_frame_beat_in = t0_frame_beat_out;
    assign t2_frame_beat_in = t1_frame_beat_out;
    assign t3_frame_beat_in = t2_frame_beat_out;
    assign t4_frame_beat_in = t3_frame_beat_out;
    assign t5_frame_beat_in = t4_frame_beat_out;
    assign t6_frame_beat_in = t5_frame_beat_out;
    assign t7_frame_beat_in = t6_frame_beat_out;
    assign t8_frame_beat_in = t7_frame_beat_out;
    assign t9_frame_beat_in = t8_frame_beat_out;
    assign ta_frame_beat_in = t9_frame_beat_out;
    assign tb_frame_beat_in = ta_frame_beat_out;
    assign tc_frame_beat_in = tb_frame_beat_out;
    assign td_frame_beat_in = tc_frame_beat_out;
    assign te_frame_beat_in = td_frame_beat_out;
    assign tf_frame_beat_in = te_frame_beat_out;
    assign out = tf_frame_beat_out;

    logic t0_in_valid, t1_in_valid, t2_in_valid, t3_in_valid;
    logic t4_in_valid, t5_in_valid, t6_in_valid, t7_in_valid;
    logic t8_in_valid, t9_in_valid, ta_in_valid, tb_in_valid;
    logic tc_in_valid, td_in_valid, te_in_valid, tf_in_valid;

    logic t0_out_ready, t1_out_ready, t2_out_ready, t3_out_ready;
    logic t4_out_ready, t5_out_ready, t6_out_ready, t7_out_ready;
    logic t8_out_ready, t9_out_ready, ta_out_ready, tb_out_ready;
    logic tc_out_ready, td_out_ready, te_out_ready, tf_out_ready;

    logic t0_in_ready, t1_in_ready, t2_in_ready, t3_in_ready;
    logic t4_in_ready, t5_in_ready, t6_in_ready, t7_in_ready;
    logic t8_in_ready, t9_in_ready, ta_in_ready, tb_in_ready;
    logic tc_in_ready, td_in_ready, te_in_ready, tf_in_ready;

    logic t0_out_valid, t1_out_valid, t2_out_valid, t3_out_valid;
    logic t4_out_valid, t5_out_valid, t6_out_valid, t7_out_valid;
    logic t8_out_valid, t9_out_valid, ta_out_valid, tb_out_valid;
    logic tc_out_valid, td_out_valid, te_out_valid, tf_out_valid;

    assign t0_in_valid = in_valid;
    assign t1_in_valid = t0_out_valid;
    assign t2_in_valid = t1_out_valid;
    assign t3_in_valid = t2_out_valid;
    assign t4_in_valid = t3_out_valid;
    assign t5_in_valid = t4_out_valid;
    assign t6_in_valid = t5_out_valid;
    assign t7_in_valid = t6_out_valid;
    assign t8_in_valid = t7_out_valid;
    assign t9_in_valid = t8_out_valid;
    assign ta_in_valid = t9_out_valid;
    assign tb_in_valid = ta_out_valid;
    assign tc_in_valid = tb_out_valid;
    assign td_in_valid = tc_out_valid;
    assign te_in_valid = td_out_valid;
    assign tf_in_valid = te_out_valid;
    assign out_valid = tf_out_valid;

    assign tf_out_ready = out_ready;
    assign te_out_ready = tf_in_ready;
    assign td_out_ready = te_in_ready;
    assign tc_out_ready = td_in_ready;
    assign tb_out_ready = tc_in_ready;
    assign ta_out_ready = tb_in_ready;
    assign t9_out_ready = ta_in_ready;
    assign t8_out_ready = t9_in_ready;
    assign t7_out_ready = t8_in_ready;
    assign t6_out_ready = t7_in_ready;
    assign t5_out_ready = t6_in_ready;
    assign t4_out_ready = t5_in_ready;
    assign t3_out_ready = t4_in_ready;
    assign t2_out_ready = t3_in_ready;
    assign t1_out_ready = t2_in_ready;
    assign t0_out_ready = t1_in_ready;
    assign in_ready = t0_in_ready;

    logic [ 7:0] t0_vc_addr;
    logic [12:0] t1_vc_addr;
    logic [12:0] t2_vc_addr;
    logic [12:0] t3_vc_addr;
    logic [12:0] t4_vc_addr;
    logic [11:0] t5_vc_addr;
    logic [ 7:0] t6_vc_addr;
    logic [ 7:0] t7_vc_addr;
    logic [ 7:0] t8_vc_addr;
    logic [ 7:0] t9_vc_addr;
    logic [ 7:0] ta_vc_addr;
    logic [ 7:0] tb_vc_addr;
    logic [ 7:0] tc_vc_addr;
    logic [ 7:0] td_vc_addr;
    logic [ 7:0] te_vc_addr;
    logic [ 7:0] tf_vc_addr;

    logic [ 53:0] t0_vc_node;
    logic [305:0] t1_vc_node;
    logic [611:0] t2_vc_node;
    logic [611:0] t3_vc_node;
    logic [557:0] t4_vc_node;
    logic [413:0] t5_vc_node;
    logic [ 53:0] t6_vc_node;
    logic [ 53:0] t7_vc_node;
    logic [ 53:0] t8_vc_node;
    logic [ 53:0] t9_vc_node;
    logic [ 53:0] ta_vc_node;
    logic [ 53:0] tb_vc_node;
    logic [ 53:0] tc_vc_node;
    logic [ 53:0] td_vc_node;
    logic [ 53:0] te_vc_node;
    logic [ 53:0] tf_vc_node;

    logic [ 7:0] t0_vc_init_addr_in;
    logic [12:0] t1_vc_init_addr_in;
    logic [12:0] t2_vc_init_addr_in;
    logic [12:0] t3_vc_init_addr_in;
    logic [12:0] t4_vc_init_addr_in;
    logic [11:0] t5_vc_init_addr_in;
    logic [ 7:0] t6_vc_init_addr_in;
    logic [ 7:0] t7_vc_init_addr_in;
    logic [ 7:0] t8_vc_init_addr_in;
    logic [ 7:0] t9_vc_init_addr_in;
    logic [ 7:0] ta_vc_init_addr_in;
    logic [ 7:0] tb_vc_init_addr_in;
    logic [ 7:0] tc_vc_init_addr_in;
    logic [ 7:0] td_vc_init_addr_in;
    logic [ 7:0] te_vc_init_addr_in;
    logic [ 7:0] tf_vc_init_addr_in;

    logic [ 7:0] t0_vc_init_addr_out;
    logic [12:0] t1_vc_init_addr_out;
    logic [12:0] t2_vc_init_addr_out;
    logic [12:0] t3_vc_init_addr_out;
    logic [12:0] t4_vc_init_addr_out;
    logic [11:0] t5_vc_init_addr_out;
    logic [ 7:0] t6_vc_init_addr_out;
    logic [ 7:0] t7_vc_init_addr_out;
    logic [ 7:0] t8_vc_init_addr_out;
    logic [ 7:0] t9_vc_init_addr_out;
    logic [ 7:0] ta_vc_init_addr_out;
    logic [ 7:0] tb_vc_init_addr_out;
    logic [ 7:0] tc_vc_init_addr_out;
    logic [ 7:0] td_vc_init_addr_out;
    logic [ 7:0] te_vc_init_addr_out;
    logic [ 7:0] tf_vc_init_addr_out;

    assign t0_vc_init_addr_in = addr[0] ? 2 : 1;
    assign t1_vc_init_addr_in = t0_vc_init_addr_out;
    assign t2_vc_init_addr_in = t1_vc_init_addr_out;
    assign t3_vc_init_addr_in = t2_vc_init_addr_out;
    assign t4_vc_init_addr_in = t3_vc_init_addr_out;
    assign t5_vc_init_addr_in = t4_vc_init_addr_out;
    assign t6_vc_init_addr_in = t5_vc_init_addr_out;
    assign t7_vc_init_addr_in = t6_vc_init_addr_out;
    assign t8_vc_init_addr_in = t7_vc_init_addr_out;
    assign t9_vc_init_addr_in = t8_vc_init_addr_out;
    assign ta_vc_init_addr_in = t9_vc_init_addr_out;
    assign tb_vc_init_addr_in = ta_vc_init_addr_out;
    assign tc_vc_init_addr_in = tb_vc_init_addr_out;
    assign td_vc_init_addr_in = tc_vc_init_addr_out;
    assign te_vc_init_addr_in = td_vc_init_addr_out;
    assign tf_vc_init_addr_in = te_vc_init_addr_out;

    logic [7:0] t0_vc_max_match_in, t1_vc_max_match_in, t2_vc_max_match_in, t3_vc_max_match_in;
    logic [7:0] t4_vc_max_match_in, t5_vc_max_match_in, t6_vc_max_match_in, t7_vc_max_match_in;
    logic [7:0] t8_vc_max_match_in, t9_vc_max_match_in, ta_vc_max_match_in, tb_vc_max_match_in;
    logic [7:0] tc_vc_max_match_in, td_vc_max_match_in, te_vc_max_match_in, tf_vc_max_match_in;

    logic [7:0] t0_vc_max_match_out, t1_vc_max_match_out, t2_vc_max_match_out, t3_vc_max_match_out;
    logic [7:0] t4_vc_max_match_out, t5_vc_max_match_out, t6_vc_max_match_out, t7_vc_max_match_out;
    logic [7:0] t8_vc_max_match_out, t9_vc_max_match_out, ta_vc_max_match_out, tb_vc_max_match_out;
    logic [7:0] tc_vc_max_match_out, td_vc_max_match_out, te_vc_max_match_out, tf_vc_max_match_out;

    assign t0_vc_max_match_in = 0;
    assign t1_vc_max_match_in = t0_vc_max_match_out;
    assign t2_vc_max_match_in = t1_vc_max_match_out;
    assign t3_vc_max_match_in = t2_vc_max_match_out;
    assign t4_vc_max_match_in = t3_vc_max_match_out;
    assign t5_vc_max_match_in = t4_vc_max_match_out;
    assign t6_vc_max_match_in = t5_vc_max_match_out;
    assign t7_vc_max_match_in = t6_vc_max_match_out;
    assign t8_vc_max_match_in = t7_vc_max_match_out;
    assign t9_vc_max_match_in = t8_vc_max_match_out;
    assign ta_vc_max_match_in = t9_vc_max_match_out;
    assign tb_vc_max_match_in = ta_vc_max_match_out;
    assign tc_vc_max_match_in = tb_vc_max_match_out;
    assign td_vc_max_match_in = tc_vc_max_match_out;
    assign te_vc_max_match_in = td_vc_max_match_out;
    assign tf_vc_max_match_in = te_vc_max_match_out;

    logic [127:0] t0_vc_prefix_in, t1_vc_prefix_in, t2_vc_prefix_in, t3_vc_prefix_in;
    logic [127:0] t4_vc_prefix_in, t5_vc_prefix_in, t6_vc_prefix_in, t7_vc_prefix_in;
    logic [127:0] t8_vc_prefix_in, t9_vc_prefix_in, ta_vc_prefix_in, tb_vc_prefix_in;
    logic [127:0] tc_vc_prefix_in, td_vc_prefix_in, te_vc_prefix_in, tf_vc_prefix_in;

    logic [127:0] t0_vc_prefix_out, t1_vc_prefix_out, t2_vc_prefix_out, t3_vc_prefix_out;
    logic [127:0] t4_vc_prefix_out, t5_vc_prefix_out, t6_vc_prefix_out, t7_vc_prefix_out;
    logic [127:0] t8_vc_prefix_out, t9_vc_prefix_out, ta_vc_prefix_out, tb_vc_prefix_out;
    logic [127:0] tc_vc_prefix_out, td_vc_prefix_out, te_vc_prefix_out, tf_vc_prefix_out;

    assign t0_vc_prefix_in = addr;
    assign t1_vc_prefix_in = t0_vc_prefix_out;
    assign t2_vc_prefix_in = t1_vc_prefix_out;
    assign t3_vc_prefix_in = t2_vc_prefix_out;
    assign t4_vc_prefix_in = t3_vc_prefix_out;
    assign t5_vc_prefix_in = t4_vc_prefix_out;
    assign t6_vc_prefix_in = t5_vc_prefix_out;
    assign t7_vc_prefix_in = t6_vc_prefix_out;
    assign t8_vc_prefix_in = t7_vc_prefix_out;
    assign t9_vc_prefix_in = t8_vc_prefix_out;
    assign ta_vc_prefix_in = t9_vc_prefix_out;
    assign tb_vc_prefix_in = ta_vc_prefix_out;
    assign tc_vc_prefix_in = tb_vc_prefix_out;
    assign td_vc_prefix_in = tc_vc_prefix_out;
    assign te_vc_prefix_in = td_vc_prefix_out;
    assign tf_vc_prefix_in = te_vc_prefix_out;

    logic [4:0] t0_vc_next_hop_in, t1_vc_next_hop_in, t2_vc_next_hop_in, t3_vc_next_hop_in;
    logic [4:0] t4_vc_next_hop_in, t5_vc_next_hop_in, t6_vc_next_hop_in, t7_vc_next_hop_in;
    logic [4:0] t8_vc_next_hop_in, t9_vc_next_hop_in, ta_vc_next_hop_in, tb_vc_next_hop_in;
    logic [4:0] tc_vc_next_hop_in, td_vc_next_hop_in, te_vc_next_hop_in, tf_vc_next_hop_in;

    logic [4:0] t0_vc_next_hop_out, t1_vc_next_hop_out, t2_vc_next_hop_out, t3_vc_next_hop_out;
    logic [4:0] t4_vc_next_hop_out, t5_vc_next_hop_out, t6_vc_next_hop_out, t7_vc_next_hop_out;
    logic [4:0] t8_vc_next_hop_out, t9_vc_next_hop_out, ta_vc_next_hop_out, tb_vc_next_hop_out;
    logic [4:0] tc_vc_next_hop_out, td_vc_next_hop_out, te_vc_next_hop_out, tf_vc_next_hop_out;

    assign t0_vc_next_hop_in = default_next_hop;
    assign t1_vc_next_hop_in = t0_vc_next_hop_out;
    assign t2_vc_next_hop_in = t1_vc_next_hop_out;
    assign t3_vc_next_hop_in = t2_vc_next_hop_out;
    assign t4_vc_next_hop_in = t3_vc_next_hop_out;
    assign t5_vc_next_hop_in = t4_vc_next_hop_out;
    assign t6_vc_next_hop_in = t5_vc_next_hop_out;
    assign t7_vc_next_hop_in = t6_vc_next_hop_out;
    assign t8_vc_next_hop_in = t7_vc_next_hop_out;
    assign t9_vc_next_hop_in = t8_vc_next_hop_out;
    assign ta_vc_next_hop_in = t9_vc_next_hop_out;
    assign tb_vc_next_hop_in = ta_vc_next_hop_out;
    assign tc_vc_next_hop_in = tb_vc_next_hop_out;
    assign td_vc_next_hop_in = tc_vc_next_hop_out;
    assign te_vc_next_hop_in = td_vc_next_hop_out;
    assign tf_vc_next_hop_in = te_vc_next_hop_out;

    logic [BT_ADDR_WIDTH-1:0] t0_bt_addr, t1_bt_addr, t2_bt_addr, t3_bt_addr;
    logic [BT_ADDR_WIDTH-1:0] t4_bt_addr, t5_bt_addr, t6_bt_addr, t7_bt_addr;
    logic [BT_ADDR_WIDTH-1:0] t8_bt_addr, t9_bt_addr, ta_bt_addr, tb_bt_addr;
    logic [BT_ADDR_WIDTH-1:0] tc_bt_addr, td_bt_addr, te_bt_addr, tf_bt_addr;

    logic [35:0] t0_bt_node, t1_bt_node, t2_bt_node, t3_bt_node;
    logic [35:0] t4_bt_node, t5_bt_node, t6_bt_node, t7_bt_node;
    logic [35:0] t8_bt_node, t9_bt_node, ta_bt_node, tb_bt_node;
    logic [35:0] tc_bt_node, td_bt_node, te_bt_node, tf_bt_node;

    logic [BT_ADDR_WIDTH-1:0] t0_bt_init_addr_in, t1_bt_init_addr_in, t2_bt_init_addr_in, t3_bt_init_addr_in;
    logic [BT_ADDR_WIDTH-1:0] t4_bt_init_addr_in, t5_bt_init_addr_in, t6_bt_init_addr_in, t7_bt_init_addr_in;
    logic [BT_ADDR_WIDTH-1:0] t8_bt_init_addr_in, t9_bt_init_addr_in, ta_bt_init_addr_in, tb_bt_init_addr_in;
    logic [BT_ADDR_WIDTH-1:0] tc_bt_init_addr_in, td_bt_init_addr_in, te_bt_init_addr_in, tf_bt_init_addr_in;

    logic [BT_ADDR_WIDTH-1:0] t0_bt_init_addr_out, t1_bt_init_addr_out, t2_bt_init_addr_out, t3_bt_init_addr_out;
    logic [BT_ADDR_WIDTH-1:0] t4_bt_init_addr_out, t5_bt_init_addr_out, t6_bt_init_addr_out, t7_bt_init_addr_out;
    logic [BT_ADDR_WIDTH-1:0] t8_bt_init_addr_out, t9_bt_init_addr_out, ta_bt_init_addr_out, tb_bt_init_addr_out;
    logic [BT_ADDR_WIDTH-1:0] tc_bt_init_addr_out, td_bt_init_addr_out, te_bt_init_addr_out, tf_bt_init_addr_out;

    assign t0_bt_init_addr_in = addr[0] ? 2 : 1;
    assign t1_bt_init_addr_in = t0_bt_init_addr_out;
    assign t2_bt_init_addr_in = t1_bt_init_addr_out;
    assign t3_bt_init_addr_in = t2_bt_init_addr_out;
    assign t4_bt_init_addr_in = t3_bt_init_addr_out;
    assign t5_bt_init_addr_in = t4_bt_init_addr_out;
    assign t6_bt_init_addr_in = t5_bt_init_addr_out;
    assign t7_bt_init_addr_in = t6_bt_init_addr_out;
    assign t8_bt_init_addr_in = t7_bt_init_addr_out;
    assign t9_bt_init_addr_in = t8_bt_init_addr_out;
    assign ta_bt_init_addr_in = t9_bt_init_addr_out;
    assign tb_bt_init_addr_in = ta_bt_init_addr_out;
    assign tc_bt_init_addr_in = tb_bt_init_addr_out;
    assign td_bt_init_addr_in = tc_bt_init_addr_out;
    assign te_bt_init_addr_in = td_bt_init_addr_out;
    assign tf_bt_init_addr_in = te_bt_init_addr_out;

    logic [7:0] t0_bt_max_match_in, t1_bt_max_match_in, t2_bt_max_match_in, t3_bt_max_match_in;
    logic [7:0] t4_bt_max_match_in, t5_bt_max_match_in, t6_bt_max_match_in, t7_bt_max_match_in;
    logic [7:0] t8_bt_max_match_in, t9_bt_max_match_in, ta_bt_max_match_in, tb_bt_max_match_in;
    logic [7:0] tc_bt_max_match_in, td_bt_max_match_in, te_bt_max_match_in, tf_bt_max_match_in;

    logic [7:0] t0_bt_max_match_out, t1_bt_max_match_out, t2_bt_max_match_out, t3_bt_max_match_out;
    logic [7:0] t4_bt_max_match_out, t5_bt_max_match_out, t6_bt_max_match_out, t7_bt_max_match_out;
    logic [7:0] t8_bt_max_match_out, t9_bt_max_match_out, ta_bt_max_match_out, tb_bt_max_match_out;
    logic [7:0] tc_bt_max_match_out, td_bt_max_match_out, te_bt_max_match_out, tf_bt_max_match_out;

    assign t0_bt_max_match_in = 0;
    assign t1_bt_max_match_in = t0_bt_max_match_out;
    assign t2_bt_max_match_in = t1_bt_max_match_out;
    assign t3_bt_max_match_in = t2_bt_max_match_out;
    assign t4_bt_max_match_in = t3_bt_max_match_out;
    assign t5_bt_max_match_in = t4_bt_max_match_out;
    assign t6_bt_max_match_in = t5_bt_max_match_out;
    assign t7_bt_max_match_in = t6_bt_max_match_out;
    assign t8_bt_max_match_in = t7_bt_max_match_out;
    assign t9_bt_max_match_in = t8_bt_max_match_out;
    assign ta_bt_max_match_in = t9_bt_max_match_out;
    assign tb_bt_max_match_in = ta_bt_max_match_out;
    assign tc_bt_max_match_in = tb_bt_max_match_out;
    assign td_bt_max_match_in = tc_bt_max_match_out;
    assign te_bt_max_match_in = td_bt_max_match_out;
    assign tf_bt_max_match_in = te_bt_max_match_out;

    logic [127:0] t0_bt_prefix_in, t1_bt_prefix_in, t2_bt_prefix_in, t3_bt_prefix_in;
    logic [127:0] t4_bt_prefix_in, t5_bt_prefix_in, t6_bt_prefix_in, t7_bt_prefix_in;
    logic [127:0] t8_bt_prefix_in, t9_bt_prefix_in, ta_bt_prefix_in, tb_bt_prefix_in;
    logic [127:0] tc_bt_prefix_in, td_bt_prefix_in, te_bt_prefix_in, tf_bt_prefix_in;

    logic [127:0] t0_bt_prefix_out, t1_bt_prefix_out, t2_bt_prefix_out, t3_bt_prefix_out;
    logic [127:0] t4_bt_prefix_out, t5_bt_prefix_out, t6_bt_prefix_out, t7_bt_prefix_out;
    logic [127:0] t8_bt_prefix_out, t9_bt_prefix_out, ta_bt_prefix_out, tb_bt_prefix_out;
    logic [127:0] tc_bt_prefix_out, td_bt_prefix_out, te_bt_prefix_out, tf_bt_prefix_out;

    assign t0_bt_prefix_in = addr;
    assign t1_bt_prefix_in = t0_bt_prefix_out;
    assign t2_bt_prefix_in = t1_bt_prefix_out;
    assign t3_bt_prefix_in = t2_bt_prefix_out;
    assign t4_bt_prefix_in = t3_bt_prefix_out;
    assign t5_bt_prefix_in = t4_bt_prefix_out;
    assign t6_bt_prefix_in = t5_bt_prefix_out;
    assign t7_bt_prefix_in = t6_bt_prefix_out;
    assign t8_bt_prefix_in = t7_bt_prefix_out;
    assign t9_bt_prefix_in = t8_bt_prefix_out;
    assign ta_bt_prefix_in = t9_bt_prefix_out;
    assign tb_bt_prefix_in = ta_bt_prefix_out;
    assign tc_bt_prefix_in = tb_bt_prefix_out;
    assign td_bt_prefix_in = tc_bt_prefix_out;
    assign te_bt_prefix_in = td_bt_prefix_out;
    assign tf_bt_prefix_in = te_bt_prefix_out;

    logic [4:0] t0_bt_next_hop_in, t1_bt_next_hop_in, t2_bt_next_hop_in, t3_bt_next_hop_in;
    logic [4:0] t4_bt_next_hop_in, t5_bt_next_hop_in, t6_bt_next_hop_in, t7_bt_next_hop_in;
    logic [4:0] t8_bt_next_hop_in, t9_bt_next_hop_in, ta_bt_next_hop_in, tb_bt_next_hop_in;
    logic [4:0] tc_bt_next_hop_in, td_bt_next_hop_in, te_bt_next_hop_in, tf_bt_next_hop_in;

    logic [4:0] t0_bt_next_hop_out, t1_bt_next_hop_out, t2_bt_next_hop_out, t3_bt_next_hop_out;
    logic [4:0] t4_bt_next_hop_out, t5_bt_next_hop_out, t6_bt_next_hop_out, t7_bt_next_hop_out;
    logic [4:0] t8_bt_next_hop_out, t9_bt_next_hop_out, ta_bt_next_hop_out, tb_bt_next_hop_out;
    logic [4:0] tc_bt_next_hop_out, td_bt_next_hop_out, te_bt_next_hop_out, tf_bt_next_hop_out;

    assign t0_bt_next_hop_in = default_next_hop;
    assign t1_bt_next_hop_in = t0_bt_next_hop_out;
    assign t2_bt_next_hop_in = t1_bt_next_hop_out;
    assign t3_bt_next_hop_in = t2_bt_next_hop_out;
    assign t4_bt_next_hop_in = t3_bt_next_hop_out;
    assign t5_bt_next_hop_in = t4_bt_next_hop_out;
    assign t6_bt_next_hop_in = t5_bt_next_hop_out;
    assign t7_bt_next_hop_in = t6_bt_next_hop_out;
    assign t8_bt_next_hop_in = t7_bt_next_hop_out;
    assign t9_bt_next_hop_in = t8_bt_next_hop_out;
    assign ta_bt_next_hop_in = t9_bt_next_hop_out;
    assign tb_bt_next_hop_in = ta_bt_next_hop_out;
    assign tc_bt_next_hop_in = tb_bt_next_hop_out;
    assign td_bt_next_hop_in = tc_bt_next_hop_out;
    assign te_bt_next_hop_in = td_bt_next_hop_out;
    assign tf_bt_next_hop_in = te_bt_next_hop_out;

    assign next_hop = tf_vc_max_match_out >= tf_bt_max_match_out ? tf_vc_next_hop_out : tf_bt_next_hop_out;

    trie8 t0(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(t0_frame_beat_in),
        .in_valid(t0_in_valid),
        .out_ready(t0_out_ready),
        .frame_beat_o(t0_frame_beat_out),
        .in_ready(t0_in_ready),
        .out_valid(t0_out_valid),
        .vc_addr_o(t0_vc_addr),
        .vc_node_i(t0_vc_node),
        .vc_init_addr_i(t0_vc_init_addr_in),
        .vc_max_match_i(t0_vc_max_match_in),
        .vc_remaining_prefix_i(t0_vc_prefix_in),
        .vc_next_hop_offset_i(t0_vc_next_hop_in),
        .vc_init_addr_o(t0_vc_init_addr_out),
        .vc_max_match_o(t0_vc_max_match_out),
        .vc_remaining_prefix_o(t0_vc_prefix_out),
        .vc_next_hop_offset_o(t0_vc_next_hop_out),
        .bt_addr_o(t0_bt_addr),
        .bt_node_i(t0_bt_node),
        .bt_init_addr_i(t0_bt_init_addr_in),
        .bt_max_match_i(t0_bt_max_match_in),
        .bt_remaining_prefix_i(t0_bt_prefix_in),
        .bt_next_hop_offset_i(t0_bt_next_hop_in),
        .bt_init_addr_o(t0_bt_init_addr_out),
        .bt_max_match_o(t0_bt_max_match_out),
        .bt_remaining_prefix_o(t0_bt_prefix_out),
        .bt_next_hop_offset_o(t0_bt_next_hop_out)
    );
    trie8 t1(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(t1_frame_beat_in),
        .in_valid(t1_in_valid),
        .out_ready(t1_out_ready),
        .frame_beat_o(t1_frame_beat_out),
        .in_ready(t1_in_ready),
        .out_valid(t1_out_valid),
        .vc_addr_o(t1_vc_addr),
        .vc_node_i(t1_vc_node),
        .vc_init_addr_i(t1_vc_init_addr_in),
        .vc_max_match_i(t1_vc_max_match_in),
        .vc_remaining_prefix_i(t1_vc_prefix_in),
        .vc_next_hop_offset_i(t1_vc_next_hop_in),
        .vc_init_addr_o(t1_vc_init_addr_out),
        .vc_max_match_o(t1_vc_max_match_out),
        .vc_remaining_prefix_o(t1_vc_prefix_out),
        .vc_next_hop_offset_o(t1_vc_next_hop_out),
        .bt_addr_o(t1_bt_addr),
        .bt_node_i(t1_bt_node),
        .bt_init_addr_i(t1_bt_init_addr_in),
        .bt_max_match_i(t1_bt_max_match_in),
        .bt_remaining_prefix_i(t1_bt_prefix_in),
        .bt_next_hop_offset_i(t1_bt_next_hop_in),
        .bt_init_addr_o(t1_bt_init_addr_out),
        .bt_max_match_o(t1_bt_max_match_out),
        .bt_remaining_prefix_o(t1_bt_prefix_out),
        .bt_next_hop_offset_o(t1_bt_next_hop_out)
    );
    trie8 t2(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(t2_frame_beat_in),
        .in_valid(t2_in_valid),
        .out_ready(t2_out_ready),
        .frame_beat_o(t2_frame_beat_out),
        .in_ready(t2_in_ready),
        .out_valid(t2_out_valid),
        .vc_addr_o(t2_vc_addr),
        .vc_node_i(t2_vc_node),
        .vc_init_addr_i(t2_vc_init_addr_in),
        .vc_max_match_i(t2_vc_max_match_in),
        .vc_remaining_prefix_i(t2_vc_prefix_in),
        .vc_next_hop_offset_i(t2_vc_next_hop_in),
        .vc_init_addr_o(t2_vc_init_addr_out),
        .vc_max_match_o(t2_vc_max_match_out),
        .vc_remaining_prefix_o(t2_vc_prefix_out),
        .vc_next_hop_offset_o(t2_vc_next_hop_out),
        .bt_addr_o(t2_bt_addr),
        .bt_node_i(t2_bt_node),
        .bt_init_addr_i(t2_bt_init_addr_in),
        .bt_max_match_i(t2_bt_max_match_in),
        .bt_remaining_prefix_i(t2_bt_prefix_in),
        .bt_next_hop_offset_i(t2_bt_next_hop_in),
        .bt_init_addr_o(t2_bt_init_addr_out),
        .bt_max_match_o(t2_bt_max_match_out),
        .bt_remaining_prefix_o(t2_bt_prefix_out),
        .bt_next_hop_offset_o(t2_bt_next_hop_out)
    );
    trie8 t3(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(t3_frame_beat_in),
        .in_valid(t3_in_valid),
        .out_ready(t3_out_ready),
        .frame_beat_o(t3_frame_beat_out),
        .in_ready(t3_in_ready),
        .out_valid(t3_out_valid),
        .vc_addr_o(t3_vc_addr),
        .vc_node_i(t3_vc_node),
        .vc_init_addr_i(t3_vc_init_addr_in),
        .vc_max_match_i(t3_vc_max_match_in),
        .vc_remaining_prefix_i(t3_vc_prefix_in),
        .vc_next_hop_offset_i(t3_vc_next_hop_in),
        .vc_init_addr_o(t3_vc_init_addr_out),
        .vc_max_match_o(t3_vc_max_match_out),
        .vc_remaining_prefix_o(t3_vc_prefix_out),
        .vc_next_hop_offset_o(t3_vc_next_hop_out),
        .bt_addr_o(t3_bt_addr),
        .bt_node_i(t3_bt_node),
        .bt_init_addr_i(t3_bt_init_addr_in),
        .bt_max_match_i(t3_bt_max_match_in),
        .bt_remaining_prefix_i(t3_bt_prefix_in),
        .bt_next_hop_offset_i(t3_bt_next_hop_in),
        .bt_init_addr_o(t3_bt_init_addr_out),
        .bt_max_match_o(t3_bt_max_match_out),
        .bt_remaining_prefix_o(t3_bt_prefix_out),
        .bt_next_hop_offset_o(t3_bt_next_hop_out)
    );
    trie8 t4(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(t4_frame_beat_in),
        .in_valid(t4_in_valid),
        .out_ready(t4_out_ready),
        .frame_beat_o(t4_frame_beat_out),
        .in_ready(t4_in_ready),
        .out_valid(t4_out_valid),
        .vc_addr_o(t4_vc_addr),
        .vc_node_i(t4_vc_node),
        .vc_init_addr_i(t4_vc_init_addr_in),
        .vc_max_match_i(t4_vc_max_match_in),
        .vc_remaining_prefix_i(t4_vc_prefix_in),
        .vc_next_hop_offset_i(t4_vc_next_hop_in),
        .vc_init_addr_o(t4_vc_init_addr_out),
        .vc_max_match_o(t4_vc_max_match_out),
        .vc_remaining_prefix_o(t4_vc_prefix_out),
        .vc_next_hop_offset_o(t4_vc_next_hop_out),
        .bt_addr_o(t4_bt_addr),
        .bt_node_i(t4_bt_node),
        .bt_init_addr_i(t4_bt_init_addr_in),
        .bt_max_match_i(t4_bt_max_match_in),
        .bt_remaining_prefix_i(t4_bt_prefix_in),
        .bt_next_hop_offset_i(t4_bt_next_hop_in),
        .bt_init_addr_o(t4_bt_init_addr_out),
        .bt_max_match_o(t4_bt_max_match_out),
        .bt_remaining_prefix_o(t4_bt_prefix_out),
        .bt_next_hop_offset_o(t4_bt_next_hop_out)
    );
    trie8 t5(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(t5_frame_beat_in),
        .in_valid(t5_in_valid),
        .out_ready(t5_out_ready),
        .frame_beat_o(t5_frame_beat_out),
        .in_ready(t5_in_ready),
        .out_valid(t5_out_valid),
        .vc_addr_o(t5_vc_addr),
        .vc_node_i(t5_vc_node),
        .vc_init_addr_i(t5_vc_init_addr_in),
        .vc_max_match_i(t5_vc_max_match_in),
        .vc_remaining_prefix_i(t5_vc_prefix_in),
        .vc_next_hop_offset_i(t5_vc_next_hop_in),
        .vc_init_addr_o(t5_vc_init_addr_out),
        .vc_max_match_o(t5_vc_max_match_out),
        .vc_remaining_prefix_o(t5_vc_prefix_out),
        .vc_next_hop_offset_o(t5_vc_next_hop_out),
        .bt_addr_o(t5_bt_addr),
        .bt_node_i(t5_bt_node),
        .bt_init_addr_i(t5_bt_init_addr_in),
        .bt_max_match_i(t5_bt_max_match_in),
        .bt_remaining_prefix_i(t5_bt_prefix_in),
        .bt_next_hop_offset_i(t5_bt_next_hop_in),
        .bt_init_addr_o(t5_bt_init_addr_out),
        .bt_max_match_o(t5_bt_max_match_out),
        .bt_remaining_prefix_o(t5_bt_prefix_out),
        .bt_next_hop_offset_o(t5_bt_next_hop_out)
    );
    trie8 t6(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(t6_frame_beat_in),
        .in_valid(t6_in_valid),
        .out_ready(t6_out_ready),
        .frame_beat_o(t6_frame_beat_out),
        .in_ready(t6_in_ready),
        .out_valid(t6_out_valid),
        .vc_addr_o(t6_vc_addr),
        .vc_node_i(t6_vc_node),
        .vc_init_addr_i(t6_vc_init_addr_in),
        .vc_max_match_i(t6_vc_max_match_in),
        .vc_remaining_prefix_i(t6_vc_prefix_in),
        .vc_next_hop_offset_i(t6_vc_next_hop_in),
        .vc_init_addr_o(t6_vc_init_addr_out),
        .vc_max_match_o(t6_vc_max_match_out),
        .vc_remaining_prefix_o(t6_vc_prefix_out),
        .vc_next_hop_offset_o(t6_vc_next_hop_out),
        .bt_addr_o(t6_bt_addr),
        .bt_node_i(t6_bt_node),
        .bt_init_addr_i(t6_bt_init_addr_in),
        .bt_max_match_i(t6_bt_max_match_in),
        .bt_remaining_prefix_i(t6_bt_prefix_in),
        .bt_next_hop_offset_i(t6_bt_next_hop_in),
        .bt_init_addr_o(t6_bt_init_addr_out),
        .bt_max_match_o(t6_bt_max_match_out),
        .bt_remaining_prefix_o(t6_bt_prefix_out),
        .bt_next_hop_offset_o(t6_bt_next_hop_out)
    );
    trie8 t7(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(t7_frame_beat_in),
        .in_valid(t7_in_valid),
        .out_ready(t7_out_ready),
        .frame_beat_o(t7_frame_beat_out),
        .in_ready(t7_in_ready),
        .out_valid(t7_out_valid),
        .vc_addr_o(t7_vc_addr),
        .vc_node_i(t7_vc_node),
        .vc_init_addr_i(t7_vc_init_addr_in),
        .vc_max_match_i(t7_vc_max_match_in),
        .vc_remaining_prefix_i(t7_vc_prefix_in),
        .vc_next_hop_offset_i(t7_vc_next_hop_in),
        .vc_init_addr_o(t7_vc_init_addr_out),
        .vc_max_match_o(t7_vc_max_match_out),
        .vc_remaining_prefix_o(t7_vc_prefix_out),
        .vc_next_hop_offset_o(t7_vc_next_hop_out),
        .bt_addr_o(t7_bt_addr),
        .bt_node_i(t7_bt_node),
        .bt_init_addr_i(t7_bt_init_addr_in),
        .bt_max_match_i(t7_bt_max_match_in),
        .bt_remaining_prefix_i(t7_bt_prefix_in),
        .bt_next_hop_offset_i(t7_bt_next_hop_in),
        .bt_init_addr_o(t7_bt_init_addr_out),
        .bt_max_match_o(t7_bt_max_match_out),
        .bt_remaining_prefix_o(t7_bt_prefix_out),
        .bt_next_hop_offset_o(t7_bt_next_hop_out)
    );
    trie8 t8(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(t8_frame_beat_in),
        .in_valid(t8_in_valid),
        .out_ready(t8_out_ready),
        .frame_beat_o(t8_frame_beat_out),
        .in_ready(t8_in_ready),
        .out_valid(t8_out_valid),
        .vc_addr_o(t8_vc_addr),
        .vc_node_i(t8_vc_node),
        .vc_init_addr_i(t8_vc_init_addr_in),
        .vc_max_match_i(t8_vc_max_match_in),
        .vc_remaining_prefix_i(t8_vc_prefix_in),
        .vc_next_hop_offset_i(t8_vc_next_hop_in),
        .vc_init_addr_o(t8_vc_init_addr_out),
        .vc_max_match_o(t8_vc_max_match_out),
        .vc_remaining_prefix_o(t8_vc_prefix_out),
        .vc_next_hop_offset_o(t8_vc_next_hop_out),
        .bt_addr_o(t8_bt_addr),
        .bt_node_i(t8_bt_node),
        .bt_init_addr_i(t8_bt_init_addr_in),
        .bt_max_match_i(t8_bt_max_match_in),
        .bt_remaining_prefix_i(t8_bt_prefix_in),
        .bt_next_hop_offset_i(t8_bt_next_hop_in),
        .bt_init_addr_o(t8_bt_init_addr_out),
        .bt_max_match_o(t8_bt_max_match_out),
        .bt_remaining_prefix_o(t8_bt_prefix_out),
        .bt_next_hop_offset_o(t8_bt_next_hop_out)
    );
    trie8 t9(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(t9_frame_beat_in),
        .in_valid(t9_in_valid),
        .out_ready(t9_out_ready),
        .frame_beat_o(t9_frame_beat_out),
        .in_ready(t9_in_ready),
        .out_valid(t9_out_valid),
        .vc_addr_o(t9_vc_addr),
        .vc_node_i(t9_vc_node),
        .vc_init_addr_i(t9_vc_init_addr_in),
        .vc_max_match_i(t9_vc_max_match_in),
        .vc_remaining_prefix_i(t9_vc_prefix_in),
        .vc_next_hop_offset_i(t9_vc_next_hop_in),
        .vc_init_addr_o(t9_vc_init_addr_out),
        .vc_max_match_o(t9_vc_max_match_out),
        .vc_remaining_prefix_o(t9_vc_prefix_out),
        .vc_next_hop_offset_o(t9_vc_next_hop_out),
        .bt_addr_o(t9_bt_addr),
        .bt_node_i(t9_bt_node),
        .bt_init_addr_i(t9_bt_init_addr_in),
        .bt_max_match_i(t9_bt_max_match_in),
        .bt_remaining_prefix_i(t9_bt_prefix_in),
        .bt_next_hop_offset_i(t9_bt_next_hop_in),
        .bt_init_addr_o(t9_bt_init_addr_out),
        .bt_max_match_o(t9_bt_max_match_out),
        .bt_remaining_prefix_o(t9_bt_prefix_out),
        .bt_next_hop_offset_o(t9_bt_next_hop_out)
    );
    trie8 ta(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(ta_frame_beat_in),
        .in_valid(ta_in_valid),
        .out_ready(ta_out_ready),
        .frame_beat_o(ta_frame_beat_out),
        .in_ready(ta_in_ready),
        .out_valid(ta_out_valid),
        .vc_addr_o(ta_vc_addr),
        .vc_node_i(ta_vc_node),
        .vc_init_addr_i(ta_vc_init_addr_in),
        .vc_max_match_i(ta_vc_max_match_in),
        .vc_remaining_prefix_i(ta_vc_prefix_in),
        .vc_next_hop_offset_i(ta_vc_next_hop_in),
        .vc_init_addr_o(ta_vc_init_addr_out),
        .vc_max_match_o(ta_vc_max_match_out),
        .vc_remaining_prefix_o(ta_vc_prefix_out),
        .vc_next_hop_offset_o(ta_vc_next_hop_out),
        .bt_addr_o(ta_bt_addr),
        .bt_node_i(ta_bt_node),
        .bt_init_addr_i(ta_bt_init_addr_in),
        .bt_max_match_i(ta_bt_max_match_in),
        .bt_remaining_prefix_i(ta_bt_prefix_in),
        .bt_next_hop_offset_i(ta_bt_next_hop_in),
        .bt_init_addr_o(ta_bt_init_addr_out),
        .bt_max_match_o(ta_bt_max_match_out),
        .bt_remaining_prefix_o(ta_bt_prefix_out),
        .bt_next_hop_offset_o(ta_bt_next_hop_out)
    );
    trie8 tb(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(tb_frame_beat_in),
        .in_valid(tb_in_valid),
        .out_ready(tb_out_ready),
        .frame_beat_o(tb_frame_beat_out),
        .in_ready(tb_in_ready),
        .out_valid(tb_out_valid),
        .vc_addr_o(tb_vc_addr),
        .vc_node_i(tb_vc_node),
        .vc_init_addr_i(tb_vc_init_addr_in),
        .vc_max_match_i(tb_vc_max_match_in),
        .vc_remaining_prefix_i(tb_vc_prefix_in),
        .vc_next_hop_offset_i(tb_vc_next_hop_in),
        .vc_init_addr_o(tb_vc_init_addr_out),
        .vc_max_match_o(tb_vc_max_match_out),
        .vc_remaining_prefix_o(tb_vc_prefix_out),
        .vc_next_hop_offset_o(tb_vc_next_hop_out),
        .bt_addr_o(tb_bt_addr),
        .bt_node_i(tb_bt_node),
        .bt_init_addr_i(tb_bt_init_addr_in),
        .bt_max_match_i(tb_bt_max_match_in),
        .bt_remaining_prefix_i(tb_bt_prefix_in),
        .bt_next_hop_offset_i(tb_bt_next_hop_in),
        .bt_init_addr_o(tb_bt_init_addr_out),
        .bt_max_match_o(tb_bt_max_match_out),
        .bt_remaining_prefix_o(tb_bt_prefix_out),
        .bt_next_hop_offset_o(tb_bt_next_hop_out)
    );
    trie8 tc(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(tc_frame_beat_in),
        .in_valid(tc_in_valid),
        .out_ready(tc_out_ready),
        .frame_beat_o(tc_frame_beat_out),
        .in_ready(tc_in_ready),
        .out_valid(tc_out_valid),
        .vc_addr_o(tc_vc_addr),
        .vc_node_i(tc_vc_node),
        .vc_init_addr_i(tc_vc_init_addr_in),
        .vc_max_match_i(tc_vc_max_match_in),
        .vc_remaining_prefix_i(tc_vc_prefix_in),
        .vc_next_hop_offset_i(tc_vc_next_hop_in),
        .vc_init_addr_o(tc_vc_init_addr_out),
        .vc_max_match_o(tc_vc_max_match_out),
        .vc_remaining_prefix_o(tc_vc_prefix_out),
        .vc_next_hop_offset_o(tc_vc_next_hop_out),
        .bt_addr_o(tc_bt_addr),
        .bt_node_i(tc_bt_node),
        .bt_init_addr_i(tc_bt_init_addr_in),
        .bt_max_match_i(tc_bt_max_match_in),
        .bt_remaining_prefix_i(tc_bt_prefix_in),
        .bt_next_hop_offset_i(tc_bt_next_hop_in),
        .bt_init_addr_o(tc_bt_init_addr_out),
        .bt_max_match_o(tc_bt_max_match_out),
        .bt_remaining_prefix_o(tc_bt_prefix_out),
        .bt_next_hop_offset_o(tc_bt_next_hop_out)
    );
    trie8 td(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(td_frame_beat_in),
        .in_valid(td_in_valid),
        .out_ready(td_out_ready),
        .frame_beat_o(td_frame_beat_out),
        .in_ready(td_in_ready),
        .out_valid(td_out_valid),
        .vc_addr_o(td_vc_addr),
        .vc_node_i(td_vc_node),
        .vc_init_addr_i(td_vc_init_addr_in),
        .vc_max_match_i(td_vc_max_match_in),
        .vc_remaining_prefix_i(td_vc_prefix_in),
        .vc_next_hop_offset_i(td_vc_next_hop_in),
        .vc_init_addr_o(td_vc_init_addr_out),
        .vc_max_match_o(td_vc_max_match_out),
        .vc_remaining_prefix_o(td_vc_prefix_out),
        .vc_next_hop_offset_o(td_vc_next_hop_out),
        .bt_addr_o(td_bt_addr),
        .bt_node_i(td_bt_node),
        .bt_init_addr_i(td_bt_init_addr_in),
        .bt_max_match_i(td_bt_max_match_in),
        .bt_remaining_prefix_i(td_bt_prefix_in),
        .bt_next_hop_offset_i(td_bt_next_hop_in),
        .bt_init_addr_o(td_bt_init_addr_out),
        .bt_max_match_o(td_bt_max_match_out),
        .bt_remaining_prefix_o(td_bt_prefix_out),
        .bt_next_hop_offset_o(td_bt_next_hop_out)
    );
    trie8 te(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(te_frame_beat_in),
        .in_valid(te_in_valid),
        .out_ready(te_out_ready),
        .frame_beat_o(te_frame_beat_out),
        .in_ready(te_in_ready),
        .out_valid(te_out_valid),
        .vc_addr_o(te_vc_addr),
        .vc_node_i(te_vc_node),
        .vc_init_addr_i(te_vc_init_addr_in),
        .vc_max_match_i(te_vc_max_match_in),
        .vc_remaining_prefix_i(te_vc_prefix_in),
        .vc_next_hop_offset_i(te_vc_next_hop_in),
        .vc_init_addr_o(te_vc_init_addr_out),
        .vc_max_match_o(te_vc_max_match_out),
        .vc_remaining_prefix_o(te_vc_prefix_out),
        .vc_next_hop_offset_o(te_vc_next_hop_out),
        .bt_addr_o(te_bt_addr),
        .bt_node_i(te_bt_node),
        .bt_init_addr_i(te_bt_init_addr_in),
        .bt_max_match_i(te_bt_max_match_in),
        .bt_remaining_prefix_i(te_bt_prefix_in),
        .bt_next_hop_offset_i(te_bt_next_hop_in),
        .bt_init_addr_o(te_bt_init_addr_out),
        .bt_max_match_o(te_bt_max_match_out),
        .bt_remaining_prefix_o(te_bt_prefix_out),
        .bt_next_hop_offset_o(te_bt_next_hop_out)
    );
    trie8 tf(
        .clk(clk),
        .rst_p(rst_p),
        .frame_beat_i(tf_frame_beat_in),
        .in_valid(tf_in_valid),
        .out_ready(tf_out_ready),
        .frame_beat_o(tf_frame_beat_out),
        .in_ready(tf_in_ready),
        .out_valid(tf_out_valid),
        .vc_addr_o(tf_vc_addr),
        .vc_node_i(tf_vc_node),
        .vc_init_addr_i(tf_vc_init_addr_in),
        .vc_max_match_i(tf_vc_max_match_in),
        .vc_remaining_prefix_i(tf_vc_prefix_in),
        .vc_next_hop_offset_i(tf_vc_next_hop_in),
        .vc_init_addr_o(tf_vc_init_addr_out),
        .vc_max_match_o(tf_vc_max_match_out),
        .vc_remaining_prefix_o(tf_vc_prefix_out),
        .vc_next_hop_offset_o(tf_vc_next_hop_out),
        .bt_addr_o(tf_bt_addr),
        .bt_node_i(tf_bt_node),
        .bt_init_addr_i(tf_bt_init_addr_in),
        .bt_max_match_i(tf_bt_max_match_in),
        .bt_remaining_prefix_i(tf_bt_prefix_in),
        .bt_next_hop_offset_i(tf_bt_next_hop_in),
        .bt_init_addr_o(tf_bt_init_addr_out),
        .bt_max_match_o(tf_bt_max_match_out),
        .bt_remaining_prefix_o(tf_bt_prefix_out),
        .bt_next_hop_offset_o(tf_bt_next_hop_out)
    );

endmodule
