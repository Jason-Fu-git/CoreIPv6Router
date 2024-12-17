`timescale 1ns / 1ps

`include "trie.vh"

module bram_data_converter_bt (
	input wire [35:0] in,
	output reg [31:0] out,

	input wire [31:0] cpu_write_in,
	output reg [35:0] cpu_write_out
);

	// BRAM node for BT is highly aligned! AWESOME!!!

	assign out = in[31:0];
	assign cpu_write_out = {4'b0, cpu_write_in};

endmodule : bram_data_converter_bt

// We need word select to determine which field to give back
// Address to fetch BRAM: 0010 0~15 000X 0000 0000 0000 XXXX XXXX
// So that we have address 0x2??????? for BRAM, and 0x2X??????? for the X-th trie.
// | 31-28 | 27-24 | 23-20 | 19-16 | 15-12 | 11--8 |  7--4 |  3--0 |
// |-------|-------|-------|-------|-------|-------|-------|-------|
// |     2 |  0~15 | 0 / 1 |  addr |  addr |  addr | entry | field |
// |  BRAM |  trie | vc/bt |  addr |  addr |  addr |   sel |   sel |
//                 | ... . |
//                 | adr s |
//
// The lower part is given to the converters below.
// Since the entry index is less than 15, we use 4 bits to represent it.
// field: 0000 for prefix_length, 0001 for prefix, 0010 for entry_offset, 1000 for lc (no matter what entry is) and 1100 for rc.
// Especially, the highest 4 bits 0010 means read, and we will design how to write to BRAM using the highest 4 bits 0011.

module bram_data_converter_1 (
	input wire [53:0] in,
	input wire [ 7:0] sel,
	output reg [31:0] out
);

	Node1 in_node;
	assign in_node = in;

	Node1_Aligned out_node;

	always_comb begin
		out_node.bin.entry_offset  = {27'b0, in_node.bin.entry_offset};
		out_node.bin.prefix        = {4'b0,  in_node.bin.prefix};
		out_node.bin.prefix_length = {27'b0, in_node.bin.prefix_length};
		out_node.rc = {24'b0, in_node.rc};
		out_node.lc = {24'b0, in_node.lc};
	end

	always_comb begin
		case (sel[3:0])
			4'b0000: out = out_node.bin.prefix_length;
			4'b0001: out = out_node.bin.prefix;
			4'b0010: out = out_node.bin.entry_offset;
			4'b1000: out = out_node.lc;
			4'b1100: out = out_node.rc;
			default: out = 32'h114514;
		endcase
	end

endmodule : bram_data_converter_1

module bram_data_converter_7 (
	input wire [305:0] in,
	input wire [  7:0] sel,
	output reg [ 31:0] out
);

	Node7 in_node;
	assign in_node = in;

	Entry_Aligned entry;

	always_comb begin
		entry.entry_offset  = {27'b0, in_node.bin[sel[7:4]].entry_offset};
		entry.prefix        = {4'b0,  in_node.bin[sel[7:4]].prefix};
		entry.prefix_length = {27'b0, in_node.bin[sel[7:4]].prefix_length};
	end

	always_comb begin
		case (sel[3:0])
			4'b0000: out = entry.prefix_length;
			4'b0001: out = entry.prefix;
			4'b0010: out = entry.entry_offset;
			4'b1000: out = {19'b0, in_node.lc};
			4'b1100: out = {19'b0, in_node.rc};
			default: out = 32'h114514;
		endcase
	end

endmodule : bram_data_converter_7

module bram_data_converter_15 (
	input wire [611:0] in,
	input wire [  7:0] sel,
	output reg [ 31:0] out
);

	Node15 in_node;
	assign in_node = in;

	Entry_Aligned entry;

	always_comb begin
		entry.entry_offset  = {27'b0, in_node.bin[sel[7:4]].entry_offset};
		entry.prefix        = {4'b0,  in_node.bin[sel[7:4]].prefix};
		entry.prefix_length = {27'b0, in_node.bin[sel[7:4]].prefix_length};
	end

	always_comb begin
		case (sel[3:0])
			4'b0000: out = entry.prefix_length;
			4'b0001: out = entry.prefix;
			4'b0010: out = entry.entry_offset;
			4'b1000: out = {19'b0, in_node.lc};
			4'b1100: out = {19'b0, in_node.rc};
			default: out = 32'h114514;
		endcase
	end

endmodule : bram_data_converter_15

module bram_data_converter_14 (
	input wire [557:0] in,
	input wire [  7:0] sel,
	output reg [ 31:0] out
);

	Node14 in_node;
	assign in_node = in;

	Entry_Aligned entry;

	always_comb begin
		entry.entry_offset  = {27'b0, in_node.bin[sel[7:4]].entry_offset};
		entry.prefix        = {4'b0,  in_node.bin[sel[7:4]].prefix};
		entry.prefix_length = {27'b0, in_node.bin[sel[7:4]].prefix_length};
	end

	always_comb begin
		case (sel[3:0])
			4'b0000: out = entry.prefix_length;
			4'b0001: out = entry.prefix;
			4'b0010: out = entry.entry_offset;
			4'b1000: out = {19'b0, in_node.lc};
			4'b1100: out = {19'b0, in_node.rc};
			default: out = 32'h114514;
		endcase
	end

endmodule : bram_data_converter_14

module bram_data_converter_10 (
	input wire [413:0] in,
	input wire [  7:0] sel,
	output reg [ 31:0] out
);

	Node10 in_node;
	assign in_node = in;

	Entry_Aligned entry;

	always_comb begin
		entry.entry_offset  = {27'b0, in_node.bin[sel[7:4]].entry_offset};
		entry.prefix        = {4'b0,  in_node.bin[sel[7:4]].prefix};
		entry.prefix_length = {27'b0, in_node.bin[sel[7:4]].prefix_length};
	end

	always_comb begin
		case (sel[3:0])
			4'b0000: out = entry.prefix_length;
			4'b0001: out = entry.prefix;
			4'b0010: out = entry.entry_offset;
			4'b1000: out = {20'b0, in_node.lc};
			4'b1100: out = {20'b0, in_node.rc};
			default: out = 32'h114514;
		endcase
	end

endmodule : bram_data_converter_10
