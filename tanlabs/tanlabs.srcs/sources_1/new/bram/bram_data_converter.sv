`timescale 1ns / 1ps

`include "trie.vh"

module bram_data_converter_1 (
	input wire [ 53:0] in,
	output reg [159:0] out
);

	Node1 in_node;
	assign in_node = in;

	Node1_Aligned out_node;

	always_comb begin
		out_node.bin.entry_offset  = {27'b0, in_node.bin.entry_offset};
		out_node.bin.prefix        = {4'b0,  in_node.bin.prefix};
		out_node.bin.pregix_length = {27'b0, in_node.bin.prefix_length};
		out_node.rc = {24'b0, in_node.rc};
		out_node.lc = {24'b0, in_node.lc};
	end

	assign out = out_node;

endmodule : bram_data_converter_1

module bram_data_converter_7 (
	input wire [305:0] in,
	output reg [735:0] out
);

	Node1 in_node;
	assign in_node = in;

	Node1_Aligned out_node;

	always_comb begin
		for (int i = 0; i < 7; i = i + 1) begin
			out_node.bin[i].entry_offset  = {27'b0, in_node.bin[i].entry_offset};
			out_node.bin[i].prefix        = {4'b0,  in_node.bin[i].prefix};
			out_node.bin[i].pregix_length = {27'b0, in_node.bin[i].prefix_length};
		end
		
		out_node.rc = {24'b0, in_node.rc};
		out_node.lc = {24'b0, in_node.lc};
	end

	assign out = out_node;

endmodule : bram_data_converter_7

module bram_data_converter_15 (
	input wire [ 611:0] in,
	output reg [1503:0] out
);

	Node1 in_node;
	assign in_node = in;

	Node1_Aligned out_node;

	always_comb begin
		for (int i = 0; i < 15; i = i + 1) begin
			out_node.bin[i].entry_offset  = {27'b0, in_node.bin[i].entry_offset};
			out_node.bin[i].prefix        = {4'b0,  in_node.bin[i].prefix};
			out_node.bin[i].pregix_length = {27'b0, in_node.bin[i].prefix_length};
		end
		
		out_node.rc = {24'b0, in_node.rc};
		out_node.lc = {24'b0, in_node.lc};
	end

	assign out = out_node;

endmodule : bram_data_converter_15

module bram_data_converter_14 (
	input wire [ 557:0] in,
	output reg [1407:0] out
);

	Node1 in_node;
	assign in_node = in;

	Node1_Aligned out_node;

	always_comb begin
		for (int i = 0; i < 14; i = i + 1) begin
			out_node.bin[i].entry_offset  = {27'b0, in_node.bin[i].entry_offset};
			out_node.bin[i].prefix        = {4'b0,  in_node.bin[i].prefix};
			out_node.bin[i].pregix_length = {27'b0, in_node.bin[i].prefix_length};
		end
		
		out_node.rc = {24'b0, in_node.rc};
		out_node.lc = {24'b0, in_node.lc};
	end

	assign out = out_node;

endmodule : bram_data_converter_14

module bram_data_converter_10 (
	input wire [ 413:0] in,
	output reg [1023:0] out
);

	Node1 in_node;
	assign in_node = in;

	Node1_Aligned out_node;

	always_comb begin
		for (int i = 0; i < 10; i = i + 1) begin
			out_node.bin[i].entry_offset  = {27'b0, in_node.bin[i].entry_offset};
			out_node.bin[i].prefix        = {4'b0,  in_node.bin[i].prefix};
			out_node.bin[i].pregix_length = {27'b0, in_node.bin[i].prefix_length};
		end
		
		out_node.rc = {24'b0, in_node.rc};
		out_node.lc = {24'b0, in_node.lc};
	end

	assign out = out_node;

endmodule : bram_data_converter_10
