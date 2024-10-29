`timescale 1ns / 1ps

`include "frame_datapath.vh"

module trie_lookup #(
	parameter width,
	parameter depth,
	parameter bin_size,
	parameter addr_width
)(
	input wire clk,
	input wire rst_p,
	input logic [width-1:0] node,
	input logic [addr_width-1:0] init_addr,
	input logic [7:0] max_match,
	input logic valid_i,
	output logic ready_o,
	input logic ready_i,
	output logic valid_o,
	output logic [addr_width-1:0] addr,
	output logic [addr_width] next_addr
);

	logic [3:0] count;
	logic idle;
	
	typedef enum logic [3:0] {
		IDLE, P1, P2, P3, P4,
		P5, P6, P7, P8
	} state_t;

	state_t state, next_state;

	always_ff @(posedge clk) begin
		if (rst_p) begin
			state <= IDLE;
		end else begin
			state <= next_state;
		end
	end

	
	

endmodule : trie_lookup
