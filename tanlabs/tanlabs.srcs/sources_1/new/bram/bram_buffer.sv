`timescale 1ns / 1ps

`include "trie.vh"

module bram_buffer_1 (
	input wire clk,
	input wire rst_p,
	input wire [31:0] dat_in,
	input wire [ 7:0] sel,
	input wire stb,
	output reg [53:0] buffer
);

	Node1 node;

	always_ff @(posedge clk) begin
		if (rst_p) begin
			node <= 0;
		end else begin
			if (stb) begin
				case (sel[3:0])
					4'b0000: node.bin.prefix_length <= dat_in[4:0];
					4'b0001: node.bin.prefix <= dat_in[27:0];
					4'b0010: node.bin.entry_offset <= dat_in[4:0];
					4'b1000: node.lc <= dat_in[7:0];
					4'b1100: node.rc <= dat_in[7:0];
					default: ;
				endcase
			end
		end
	end

	assign buffer = node;

endmodule

module bram_buffer_7 (
	input wire clk,
	input wire rst_p,
	input wire [31:0] dat_in,
	input wire [ 7:0] sel,
	input wire stb,
	output reg [305:0] buffer
);

	Node7 node;

	always_ff @(posedge clk) begin
		if (rst_p) begin
			node <= 0;
		end else begin
			if (stb) begin
				case (sel[3:0])
					4'b0000: node.bin[sel[7:4]].prefix_length <= dat_in[4:0];
					4'b0001: node.bin[sel[7:4]].prefix <= dat_in[27:0];
					4'b0010: node.bin[sel[7:4]].entry_offset <= dat_in[4:0];
					4'b1000: node.lc <= dat_in[7:0];
					4'b1100: node.rc <= dat_in[7:0];
					default: ;
				endcase
			end
		end
	end

	assign buffer = node;

endmodule

module bram_buffer_15 (
	input wire clk,
	input wire rst_p,
	input wire [31:0] dat_in,
	input wire [ 7:0] sel,
	input wire stb,
	output reg [611:0] buffer
);

	Node15 node;

	always_ff @(posedge clk) begin
		if (rst_p) begin
			node <= 0;
		end else begin
			if (stb) begin
				case (sel[3:0])
					4'b0000: node.bin[sel[7:4]].prefix_length <= dat_in[4:0];
					4'b0001: node.bin[sel[7:4]].prefix <= dat_in[27:0];
					4'b0010: node.bin[sel[7:4]].entry_offset <= dat_in[4:0];
					4'b1000: node.lc <= dat_in[7:0];
					4'b1100: node.rc <= dat_in[7:0];
					default: ;
				endcase
			end
		end
	end

	assign buffer = node;

endmodule

module bram_buffer_14 (
	input wire clk,
	input wire rst_p,
	input wire [31:0] dat_in,
	input wire [ 7:0] sel,
	input wire stb,
	output reg [557:0] buffer
);

	Node14 node;

	always_ff @(posedge clk) begin
		if (rst_p) begin
			node <= 0;
		end else begin
			if (stb) begin
				case (sel[3:0])
					4'b0000: node.bin[sel[7:4]].prefix_length <= dat_in[4:0];
					4'b0001: node.bin[sel[7:4]].prefix <= dat_in[27:0];
					4'b0010: node.bin[sel[7:4]].entry_offset <= dat_in[4:0];
					4'b1000: node.lc <= dat_in[7:0];
					4'b1100: node.rc <= dat_in[7:0];
					default: ;
				endcase
			end
		end
	end

	assign buffer = node;

endmodule

module bram_buffer_10 (
	input wire clk,
	input wire rst_p,
	input wire [31:0] dat_in,
	input wire [ 7:0] sel,
	input wire stb,
	output reg [413:0] buffer
);

	Node10 node;

	always_ff @(posedge clk) begin
		if (rst_p) begin
			node <= 0;
		end else begin
			if (stb) begin
				case (sel[3:0])
					4'b0000: node.bin[sel[7:4]].prefix_length <= dat_in[4:0];
					4'b0001: node.bin[sel[7:4]].prefix <= dat_in[27:0];
					4'b0010: node.bin[sel[7:4]].entry_offset <= dat_in[4:0];
					4'b1000: node.lc <= dat_in[7:0];
					4'b1100: node.rc <= dat_in[7:0];
					default: ;
				endcase
			end
		end
	end

	assign buffer = node;

endmodule
