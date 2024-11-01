`timescale 1ns / 1ps

`include "trie.vh"

// Important: each chip of BRAM should keep address 0x0 reserved!

module trie_lookup #(
	parameter width,
	parameter depth,
	parameter bin_size,
	parameter addr_width,
	parameter next_addr_width,
	parameter begin_level
)(
	input  wire                   clk,
	input  wire                   rst_p,
	input  logic [     width-1:0] node,
	input  logic [addr_width-1:0] init_addr,
	input  logic [7:0]            max_match_i,
	input  logic [127:0]          prefix_i,
	input  logic [4:0]            next_hop_offset_i,
	input  frame_beat             frame_beat_i,
	input  logic                  valid_i,
	input  logic                  skip_i,
	output logic                  ready_o,
	input  logic                  ready_i,
	output logic [127:0]          prefix_o,
	output logic [4:0]            next_hop_offset_o,
	output frame_beat             frame_beat_o,
	output logic                  valid_o,
	output logic                  skip_o,
	output logic [addr_width-1:0] addr,
	output logic [next_addr_width-1:0] next_addr,  // Addr to be given to the next chip of BRAM
	output logic [7:0]            max_match_o,
	output logic                  rea_o
);

	logic [3:0] count;
	logic idle;
	logic no_child;
	logic [7:0] now_max_match;
	logic [4:0] now_next_hop;

	always_comb begin
		now_max_match = 0;
		now_next_hop = 0;
		for (int i = 0; i < bin_size; i = i + 1) begin
			Entry entry = node[2 * addr_width + (i + 1) * ENTRY_SIZE - 1:2 * addr_width + i * ENTRY_SIZE];
			logic [27:0] mask = 28'hfffffff >> entry.prefix_length;
			if ((entry.prefix_length != 5'b11111) && ((prefix_o[27:0] & mask) == (entry.prefix & mask))) begin
				logic [7:0] match_length = begin_level + count + entry.prefix_length;
				if (match_length > now_max_match) begin
					now_max_match = match_length;
					now_next_hop = entry.entry_offset;
				end
			end
		end
	end
	
	typedef enum logic [3:0] {
		IDLE,
		LOOKUP
	} state_t;

	state_t state, next_state;

	always_ff @(posedge clk) begin
		if (rst_p) begin
			state <= IDLE;
		end else begin
			state <= next_state;
		end
	end

	always_comb begin
		case (state)
			IDLE: begin
				next_state = (valid_i && (!valid_o || ready_i)) ? (skip_i ? IDLE : LOOKUP) : IDLE;
			end
			LOOKUP: begin
				next_state = (no_child || (count == 4'd8)) ? IDLE : LOOKUP;
			end
			default: next_state = IDLE;
		endcase
	end

	assign rea_o = (state == LOOKUP);
	assign ready_o = (state == IDLE) && (!valid_o || ready_i);
	assign no_child = ~|(prefix_o[0] ? node[15:8] : node[7:0]);

	always_ff @(posedge clk) begin
		if (rst_p) begin
			valid_o <= 0;
			addr <= 0;
			skip_o <= 0;
			max_match_o <= 0;
			prefix_o <= 0;
			count <= 0;
			next_hop_offset_o <= 0;
			frame_beat_o <= 0;
			next_addr <= 0;
		end else begin
			if (ready_o && valid_i) begin
				addr <= init_addr;
				next_addr <= 0;
				skip_o <= skip_i;
				max_match_o <= max_match_i;
				prefix_o <= prefix_i;
				next_hop_offset_o <= next_hop_offset_i;
				frame_beat_o <= frame_beat_i;
				if (skip_i) begin
					valid_o <= 1;
				end else if (ready_i && valid_o) begin
					valid_o <= 0;
				end
			end else if ((state == LOOKUP) && (next_state == LOOKUP)) begin
				count <= count + 1;
				addr <= prefix_o[0] ? node[2 * addr_width - 1:addr_width] : node[addr_width-1:0];
				next_addr <= prefix_o[0] ? node[2 * addr_width - 1:addr_width] : node[addr_width-1:0];
			end else if ((state == LOOKUP) && (next_state == IDLE)) begin
				count <= 0;
				valid_o <= 1;
			end
			if ((state == LOOKUP) && (count > 0)) begin
				if (now_max_match > max_match_o) begin
					max_match_o <= now_max_match;
					next_hop_offset_o <= now_next_hop;
				end
			end
		end
	end
	

endmodule : trie_lookup
