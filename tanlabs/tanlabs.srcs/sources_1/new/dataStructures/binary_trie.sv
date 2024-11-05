`timescale 1ns / 1ps

`include "frame_datapath.vh"
`include "trie.vh"

module binary_trie (
    input wire clk,
    input wire rst_p,

    // bram signals
    input logic [35:0] node_i,
    output logic [14:0] addr_o,
    input logic [14:0] init_addr_i,
    output logic [14:0] next_addr_o,  // Addr to be given to the next chip of BRAM
    output logic rea_o,

    // pipeline inputs
    input logic [7:0] max_match_i,
    input logic [127:0] prefix_i,
    input logic [7:0] prefix_length_i,  // input should be 8N
    input logic [4:0] next_hop_addr_i,
    input fw_frame_beat_t frame_beat_i,
    input logic valid_i,
    input logic skip_i,
    output logic ready_o,  // in ready

    // pipeline outputs
    output logic [7:0] max_match_o,
    output logic [127:0] prefix_o,
    output logic [7:0] prefix_length_o,
    output logic [4:0] next_hop_addr_o,
    output fw_frame_beat_t frame_beat_o,
    output logic valid_o,
    output logic skip_o,
    input logic ready_i  // out ready
);

  logic [3:0] count;
  logic [7:0] now_max_match;
  logic [4:0] now_next_hop;

  binary_trie_node_t node;
  assign node = node_i;

  always_comb begin : Trie
    now_max_match = 0;
    now_next_hop  = 0;
    if (node.valid) begin
      if (prefix_length_o > now_max_match) begin
        now_max_match = prefix_length_o;
        now_next_hop  = node.next_hop_addr;
      end
    end
  end

  typedef enum logic [3:0] {
    IDLE,
    LOOKUP
  } state_t;

  state_t state, next_state;

  always_ff @(posedge clk) begin : StateTransition
    if (rst_p) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  always_comb begin : NextState
    case (state)
      IDLE: begin
        next_state = (valid_i && (!valid_o || ready_i)) ? (skip_i ? IDLE : LOOKUP) : IDLE;
      end
      LOOKUP: begin
        next_state = (count == 4'd8) ? IDLE : LOOKUP;
      end
      default: next_state = IDLE;
    endcase
  end

  assign rea_o   = (state == LOOKUP);
  assign ready_o = (state == IDLE) && (!valid_o || ready_i);

  always_ff @(posedge clk) begin : StateMachine
    if (rst_p) begin
      // pipeline registers
      max_match_o     <= 0;
      prefix_o        <= 0;
      prefix_length_o <= 0;
      next_hop_addr_o <= 0;
      frame_beat_o    <= 0;
      valid_o         <= 0;
      skip_o          <= 0;

      // bram registers
      addr_o          <= 0;
      next_addr_o     <= 0;

      // internal registers
      count           <= 0;
    end else begin
      if (ready_o && valid_i) begin
        // pipeline registers
        max_match_o     <= max_match_i;
        prefix_o        <= prefix_i;
        prefix_length_o <= prefix_length_i;  // prefix_length_i is 8N
        next_hop_addr_o <= next_hop_addr_i;
        frame_beat_o    <= frame_beat_i;
        skip_o          <= skip_i;
        if (skip_i) begin
          valid_o <= 1;
        end else if (ready_i && valid_o) begin
          valid_o <= 0;
        end

        // bram registers
        addr_o      <= init_addr_i;
        next_addr_o <= 0;

        // internal registers
        count       <= 0;
      end else if ((state == LOOKUP) && (next_state == LOOKUP)) begin
        count           <= count + 1;
        prefix_o        <= prefix_o >> 1;
        prefix_length_o <= prefix_length_o + 1;
        addr_o          <= prefix_o[0] ? node.rc : node.lc;
        next_addr_o     <= prefix_o[0] ? node.rc : node.lc;
      end else if ((state == LOOKUP) && (next_state == IDLE)) begin
        count   <= 0;
        valid_o <= 1;
      end
      if ((state == LOOKUP) && (count > 0)) begin
        if (now_max_match > max_match_o) begin
          max_match_o     <= now_max_match;
          next_hop_addr_o <= now_next_hop;
        end
      end
    end
  end


endmodule
