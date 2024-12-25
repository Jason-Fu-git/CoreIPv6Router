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
		case (sel)
			8'b00000010: out = out_node.bin.prefix_length;
			8'b00000011: out = out_node.bin.prefix;
			8'b00000100: out = out_node.bin.entry_offset;
			8'b00000000: out = out_node.lc;
			8'b00000001: out = out_node.rc;
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
		entry.entry_offset  = {27'b0, in_node.bin[(sel - 8'd2) / 3].entry_offset};
		entry.prefix        = {4'b0,  in_node.bin[(sel - 8'd2) / 3].prefix};
		entry.prefix_length = {27'b0, in_node.bin[(sel - 8'd2) / 3].prefix_length};
	end

	always_comb begin
		if (sel == 8'd0) begin
			out = {19'b0, in_node.lc};
		end else if (sel == 8'd1) begin
			out = {19'b0, in_node.rc};
		end else begin
			case (sel % 3)
				0: out = entry.prefix_length;
				1: out = entry.prefix;
				2: out = entry.entry_offset;
				default: out = 32'h114514;
			endcase
		end
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
		entry.entry_offset  = {27'b0, in_node.bin[(sel - 8'd2) / 3].entry_offset};
		entry.prefix        = {4'b0,  in_node.bin[(sel - 8'd2) / 3].prefix};
		entry.prefix_length = {27'b0, in_node.bin[(sel - 8'd2) / 3].prefix_length};
	end

	always_comb begin
		if (sel == 8'd0) begin
			out = {19'b0, in_node.lc};
		end else if (sel == 8'd1) begin
			out = {19'b0, in_node.rc};
		end else begin
			case (sel % 3)
				0: out = entry.prefix_length;
				1: out = entry.prefix;
				2: out = entry.entry_offset;
				default: out = 32'h114514;
			endcase
		end
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
		entry.entry_offset  = {27'b0, in_node.bin[(sel - 8'd2) / 3].entry_offset};
		entry.prefix        = {4'b0,  in_node.bin[(sel - 8'd2) / 3].prefix};
		entry.prefix_length = {27'b0, in_node.bin[(sel - 8'd2) / 3].prefix_length};
	end

	always_comb begin
		if (sel == 8'd0) begin
			out = {19'b0, in_node.lc};
		end else if (sel == 8'd1) begin
			out = {19'b0, in_node.rc};
		end else begin
			case (sel % 3)
				0: out = entry.prefix_length;
				1: out = entry.prefix;
				2: out = entry.entry_offset;
				default: out = 32'h114514;
			endcase
		end
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
		entry.entry_offset  = {27'b0, in_node.bin[(sel - 8'd2) / 3].entry_offset};
		entry.prefix        = {4'b0,  in_node.bin[(sel - 8'd2) / 3].prefix};
		entry.prefix_length = {27'b0, in_node.bin[(sel - 8'd2) / 3].prefix_length};
	end

	always_comb begin
		if (sel == 8'd0) begin
			out = {19'b0, in_node.lc};
		end else if (sel == 8'd1) begin
			out = {19'b0, in_node.rc};
		end else begin
			case (sel % 3)
				0: out = entry.prefix_length;
				1: out = entry.prefix;
				2: out = entry.entry_offset;
				default: out = 32'h114514;
			endcase
		end
	end

endmodule : bram_data_converter_10
