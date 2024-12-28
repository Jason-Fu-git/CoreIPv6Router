`timescale 1ns / 1ps

`include "frame_datapath.vh"
`include "trie.vh"

localparam VC_ENTRY_SIZE = 38;
localparam VC_LEN_WIDTH = 5;

localparam BT_ADDR_WIDTH   = 13;
localparam BT_NODE_WIDTH   = 36;

localparam OFFSET_WIDTH = 5;

localparam IP6_WIDTH = 128;
localparam MATCH_LEN_WIDTH = 8;

module trie8 #(
    parameter VC_ADDR_WIDTH,
    parameter VC_BIN_SIZE,
    parameter BEGIN_LEVEL
) (
    input wire clk,
    input wire rst_p,

    // pipeline signals
    input  frame_beat frame_beat_i,
    input  logic      in_valid,
    input  logic      out_ready,
    output frame_beat frame_beat_o,
    output logic      in_ready,
    output logic      out_valid,

    // VCTrie BRAM controller signals
    output logic [VC_ADDR_WIDTH-1:0] vc_addr_o,
    input  logic [VC_NODE_WIDTH-1:0] vc_node_i,

    // VCTrie registers between pipelines
    input  logic [  VC_ADDR_WIDTH-1:0] vc_init_addr_i,
    input  logic [MATCH_LEN_WIDTH-1:0] vc_max_match_i,
    input  logic [      IP6_WIDTH-1:0] vc_remaining_prefix_i,
    input  logic [   OFFSET_WIDTH-1:0] vc_next_hop_offset_i,
    output logic [  VC_ADDR_WIDTH-1:0] vc_init_addr_o,
    output logic [MATCH_LEN_WIDTH-1:0] vc_max_match_o,
    output logic [      IP6_WIDTH-1:0] vc_remaining_prefix_o,
    output logic [   OFFSET_WIDTH-1:0] vc_next_hop_offset_o,

    // BTrie BRAM controller signals
    output logic [BT_ADDR_WIDTH-1:0] bt_addr_o,
    input  logic [BT_NODE_WIDTH-1:0] bt_node_i,

    // BTrie registers between pipelines
    input  logic [  BT_ADDR_WIDTH-1:0] bt_init_addr_i,
    input  logic [MATCH_LEN_WIDTH-1:0] bt_max_match_i,
    input  logic [      IP6_WIDTH-1:0] bt_remaining_prefix_i,
    input  logic [   OFFSET_WIDTH-1:0] bt_next_hop_offset_i,
    output logic [  BT_ADDR_WIDTH-1:0] bt_init_addr_o,
    output logic [MATCH_LEN_WIDTH-1:0] bt_max_match_o,
    output logic [      IP6_WIDTH-1:0] bt_remaining_prefix_o,
    output logic [   OFFSET_WIDTH-1:0] bt_next_hop_offset_o
);

  localparam VC_NODE_WIDTH = ((VC_BIN_SIZE * VC_ENTRY_SIZE + 2 * VC_ADDR_WIDTH + 17)/18)*18;

  typedef enum logic [3:0] {
    IDLE,
    L0,
    L1,
    L2,
    L3,
    L4,
    L5,
    L6,
    L7,
    DONE
  } state_t;

  // Lk means this period we are trying to read a node from level k.
  // So the data will be ready at L(k+1).
  // Via combinational logic, max_match will be ready at L(k+1).
  // Then at L(k+2) max_match reg will be updated and valid.
  //
  // |      | IDLE |  L0  |  L1  |  L2  |  L3  |  L4  |  L5  |  L6  |  L7  | DONE |
  // |------|------|------|------|------|------|------|------|------|------|------|
  // | addr | none | init | adr1 | adr2 | adr3 | adr4 | adr5 | adr6 | adr7 | none |
  // | node | none | none | nod0 | nod1 | nod2 | nod3 | nod4 | nod5 | nod6 | nod7 |
  // | mchc | none | none | mch0 | mch1 | mch2 | mch3 | mch4 | mch5 | mch6 | mch7 |
  // | mchr | mch7 | prev | prev | mch0 | mch1 | mch2 | mch3 | mch4 | mch5 | mch6 |
  // | prfx | p>>8 | prfx | prfx | p>>1 | p>>2 | p>>3 | p>>4 | p>>5 | p>>6 | p>>7 |
  //
  // States that require to read a node: L0 ~ L7
  // Change addr_o at: IDLE (from init_addr_i), L0 ~ L6 (from combinational logic)
  // Change init_addr_o (next address) at: L7 (so that at DONE init_addr_o is next address)
  // Mark out_valid at: DONE (so that at IDLE out_valid is high)
  //     then, at IDLE, if out_ready, set out_valid 0
  // Inherit max_match from the previous pipeline at: IDLE (so that at L0)

  state_t state, next_state;
  logic [MATCH_LEN_WIDTH-1:0] state_level;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      state <= IDLE;
      state_level <= 0;
    end else begin
      state <= next_state;
      case (next_state)
        L0: state_level <= 0;
        L1: state_level <= 1;
        L2: state_level <= 2;
        L3: state_level <= 3;
        L4: state_level <= 4;
        L5: state_level <= 5;
        L6: state_level <= 6;
        L7: state_level <= 7;
        default: state_level <= 0;
      endcase
    end
  end

  always_comb begin
    case (state)
      IDLE:    next_state = (in_valid && in_ready) ? L0 : IDLE;
      L0:      next_state = L1;
      L1:      next_state = L2;
      L2:      next_state = L3;
      L3:      next_state = L4;
      L4:      next_state = L5;
      L5:      next_state = L6;
      L6:      next_state = L7;
      L7:      next_state = DONE;
      DONE:    next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end

  logic [  VC_ADDR_WIDTH-1:0] vc_addr_reg;
  logic [  BT_ADDR_WIDTH-1:0] bt_addr_reg;

  logic [MATCH_LEN_WIDTH-1:0] vc_now_max_match;
  logic [MATCH_LEN_WIDTH-1:0] bt_now_max_match;

  logic [   OFFSET_WIDTH-1:0] vc_now_next_hop_offset;
  logic [   OFFSET_WIDTH-1:0] bt_now_next_hop_offset;

  binary_trie_node_t bt_node;

  assign bt_node = bt_node_i;

  logic [VC_BIN_SIZE-1:0][MATCH_LEN_WIDTH-1:0] vc_max_matches;
  logic [VC_BIN_SIZE-1:0][   OFFSET_WIDTH-1:0] vc_next_hop_offsets;
  logic [VC_BIN_SIZE-1:0]                      vc_valids;

  always_comb begin
    for (int i = 0; i < VC_BIN_SIZE; i = i + 1) begin
      Entry entry = vc_node_i[2*VC_ADDR_WIDTH+(i+1)*VC_ENTRY_SIZE-1-:VC_ENTRY_SIZE];
      logic [27:0] mask = 28'hfffffff >> (28 - entry.prefix_length);
      vc_valids[i] = (entry.prefix_length != 5'b11111) && ((vc_remaining_prefix_o[27:0] & mask) == (entry.prefix & mask));
      vc_max_matches[i] = BEGIN_LEVEL + state_level + entry.prefix_length;
      vc_next_hop_offsets[i] = entry.entry_offset;
    end
  end

  always_comb begin
    vc_now_max_match       = 0;
    vc_now_next_hop_offset = 0;
    // for (int i = 0; i < VC_BIN_SIZE; i = i + 1) begin
    //   Entry entry = vc_node_i[2*VC_ADDR_WIDTH+(i+1)*VC_ENTRY_SIZE-1-:VC_ENTRY_SIZE];
    //   logic [27:0] mask = 28'hfffffff >> (28 - entry.prefix_length);
    //   if ((entry.prefix_length != 5'b11111) && ((vc_remaining_prefix_o[27:0] & mask) == (entry.prefix & mask))) begin
    //     logic [7:0] match_length = BEGIN_LEVEL + (state - L0) + entry.prefix_length;
    //     if (match_length > vc_now_max_match) begin
    //       vc_now_max_match       = match_length;
    //       vc_now_next_hop_offset = entry.entry_offset;
    //     end
    //   end
    // end
    for (int i = 0; i < VC_BIN_SIZE; i = i + 1) begin
      if (vc_valids[i] && (vc_max_matches[i] > vc_now_max_match)) begin
        vc_now_max_match = vc_max_matches[i];
        vc_now_next_hop_offset = vc_next_hop_offsets[i];
      end
    end
    bt_now_max_match       = 0;
    bt_now_next_hop_offset = 0;
    if (bt_node.valid && (BEGIN_LEVEL + (state - L0) > bt_now_max_match)) begin
      bt_now_max_match       = BEGIN_LEVEL + (state - L0);
      bt_now_next_hop_offset = bt_node.next_hop_addr;
    end
  end

  always_comb begin
    case (state)
      IDLE: begin
        vc_addr_o = 0;
        bt_addr_o = 0;
      end
      L0: begin
        vc_addr_o = vc_addr_reg;
        bt_addr_o = bt_addr_reg;
      end
      L1: begin
        vc_addr_o = vc_remaining_prefix_o[0] ? vc_node_i[2*VC_ADDR_WIDTH-1:VC_ADDR_WIDTH] : vc_node_i[VC_ADDR_WIDTH-1:0];
        bt_addr_o = bt_remaining_prefix_o[0] ? bt_node_i[2*BT_ADDR_WIDTH-1:BT_ADDR_WIDTH] : bt_node_i[BT_ADDR_WIDTH-1:0];
      end
      L2: begin
        vc_addr_o = vc_remaining_prefix_o[0] ? vc_node_i[2*VC_ADDR_WIDTH-1:VC_ADDR_WIDTH] : vc_node_i[VC_ADDR_WIDTH-1:0];
        bt_addr_o = bt_remaining_prefix_o[0] ? bt_node_i[2*BT_ADDR_WIDTH-1:BT_ADDR_WIDTH] : bt_node_i[BT_ADDR_WIDTH-1:0];
      end
      L3: begin
        vc_addr_o = vc_remaining_prefix_o[0] ? vc_node_i[2*VC_ADDR_WIDTH-1:VC_ADDR_WIDTH] : vc_node_i[VC_ADDR_WIDTH-1:0];
        bt_addr_o = bt_remaining_prefix_o[0] ? bt_node_i[2*BT_ADDR_WIDTH-1:BT_ADDR_WIDTH] : bt_node_i[BT_ADDR_WIDTH-1:0];
      end
      L4: begin
        vc_addr_o = vc_remaining_prefix_o[0] ? vc_node_i[2*VC_ADDR_WIDTH-1:VC_ADDR_WIDTH] : vc_node_i[VC_ADDR_WIDTH-1:0];
        bt_addr_o = bt_remaining_prefix_o[0] ? bt_node_i[2*BT_ADDR_WIDTH-1:BT_ADDR_WIDTH] : bt_node_i[BT_ADDR_WIDTH-1:0];
      end
      L5: begin
        vc_addr_o = vc_remaining_prefix_o[0] ? vc_node_i[2*VC_ADDR_WIDTH-1:VC_ADDR_WIDTH] : vc_node_i[VC_ADDR_WIDTH-1:0];
        bt_addr_o = bt_remaining_prefix_o[0] ? bt_node_i[2*BT_ADDR_WIDTH-1:BT_ADDR_WIDTH] : bt_node_i[BT_ADDR_WIDTH-1:0];
      end
      L6: begin
        vc_addr_o = vc_remaining_prefix_o[0] ? vc_node_i[2*VC_ADDR_WIDTH-1:VC_ADDR_WIDTH] : vc_node_i[VC_ADDR_WIDTH-1:0];
        bt_addr_o = bt_remaining_prefix_o[0] ? bt_node_i[2*BT_ADDR_WIDTH-1:BT_ADDR_WIDTH] : bt_node_i[BT_ADDR_WIDTH-1:0];
      end
      L7: begin
        vc_addr_o = vc_remaining_prefix_o[0] ? vc_node_i[2*VC_ADDR_WIDTH-1:VC_ADDR_WIDTH] : vc_node_i[VC_ADDR_WIDTH-1:0];
        bt_addr_o = bt_remaining_prefix_o[0] ? bt_node_i[2*BT_ADDR_WIDTH-1:BT_ADDR_WIDTH] : bt_node_i[BT_ADDR_WIDTH-1:0];
      end
      DONE: begin
        vc_addr_o = 0;
        bt_addr_o = 0;
      end
      default: begin
        vc_addr_o = 0;
        bt_addr_o = 0;
      end
    endcase
  end

  assign in_ready = (state == IDLE) && (!out_valid || out_ready);

  always_ff @(posedge clk) begin
    if (rst_p) begin
      frame_beat_o          <= 0;
      out_valid             <= 0;
      vc_addr_reg           <= 0;
      vc_init_addr_o        <= 0;
      vc_max_match_o        <= 0;
      vc_remaining_prefix_o <= 0;
      vc_next_hop_offset_o  <= 0;
      bt_addr_reg           <= 0;
      bt_init_addr_o        <= 0;
      bt_max_match_o        <= 0;
      bt_remaining_prefix_o <= 0;
      bt_next_hop_offset_o  <= 0;
    end else begin
      if (state == IDLE) begin
        if (in_valid && in_ready) begin
          if (out_valid) begin
            out_valid <= 0;
          end
          frame_beat_o          <= frame_beat_i;
          frame_beat_o.valid    <= 0;
          vc_addr_reg           <= vc_init_addr_i;
          vc_max_match_o        <= vc_max_match_i;
          vc_remaining_prefix_o <= vc_remaining_prefix_i;
          vc_next_hop_offset_o  <= vc_next_hop_offset_i;
          bt_addr_reg           <= bt_init_addr_i;
          bt_max_match_o        <= bt_max_match_i;
          bt_remaining_prefix_o <= bt_remaining_prefix_i;
          bt_next_hop_offset_o  <= bt_next_hop_offset_i;
        end
      end else if (state == L0) begin
        vc_remaining_prefix_o <= {1'b0, vc_remaining_prefix_o[127:1]};
        bt_remaining_prefix_o <= {1'b0, bt_remaining_prefix_o[127:1]};
      end else if ((state >= L1) && (state <= L7)) begin
        vc_remaining_prefix_o <= {1'b0, vc_remaining_prefix_o[127:1]};
        bt_remaining_prefix_o <= {1'b0, bt_remaining_prefix_o[127:1]};
        if (vc_now_max_match > vc_max_match_o) begin
          vc_max_match_o       <= vc_now_max_match;
          vc_next_hop_offset_o <= vc_now_next_hop_offset;
        end
        if (bt_now_max_match > bt_max_match_o) begin
          bt_max_match_o       <= bt_now_max_match;
          bt_next_hop_offset_o <= bt_now_next_hop_offset;
        end
      end else if (state == DONE) begin
        if (vc_now_max_match > vc_max_match_o) begin
          vc_max_match_o       <= vc_now_max_match;
          vc_next_hop_offset_o <= vc_now_next_hop_offset;
        end
        if (bt_now_max_match > bt_max_match_o) begin
          bt_max_match_o       <= bt_now_max_match;
          bt_next_hop_offset_o <= bt_now_next_hop_offset;
        end
        vc_init_addr_o <= vc_remaining_prefix_o[0] ? vc_node_i[2*VC_ADDR_WIDTH-1:VC_ADDR_WIDTH] : vc_node_i[VC_ADDR_WIDTH-1:0];
        bt_init_addr_o <= bt_remaining_prefix_o[0] ? bt_node_i[2*BT_ADDR_WIDTH-1:BT_ADDR_WIDTH] : bt_node_i[BT_ADDR_WIDTH-1:0];
        frame_beat_o.valid <= 1;
        out_valid <= 1;
      end
    end
  end

endmodule : trie8

module trie8_test (
    input wire gtclk_125_p
);

  trie8 #(
      .VC_ADDR_WIDTH(8),
      .VC_BIN_SIZE(5),
      .BEGIN_LEVEL(0)
  ) trie8_i (
      .clk(gtclk_125_p)
  );

endmodule
