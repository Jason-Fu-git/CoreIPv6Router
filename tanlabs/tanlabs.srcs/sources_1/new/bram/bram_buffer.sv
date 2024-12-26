`timescale 1ns / 1ps

`include "trie.vh"

module bram_buffer_1 (
	input wire clk,
	input wire rst_p,
	input wire [31:0] dat_in,
	input wire [ 7:0] sel,
	input wire stb,
	input wire [53:0] node_in,
	output reg [53:0] buffer
);

	Node1 node;

	always_comb begin
		node = node_in;
		case (sel[7:2])
			6'b000100: node.bin.prefix_length = dat_in[4:0];
			6'b000101: node.bin.prefix = dat_in[27:0];
			6'b000110: node.bin.entry_offset = dat_in[4:0];
			6'b000000: node.lc = dat_in[7:0];
			6'b000001: node.rc = dat_in[7:0];
			default: ;
		endcase
	end

	// always_ff @(posedge clk) begin
	// 	if (rst_p) begin
	// 		node <= 0;
	// 	end else begin
	// 		if (stb) begin
	// 			case (sel[3:0])
	// 				4'b0000: node.bin.prefix_length <= dat_in[4:0];
	// 				4'b0001: node.bin.prefix <= dat_in[27:0];
	// 				4'b0010: node.bin.entry_offset <= dat_in[4:0];
	// 				4'b1000: node.lc <= dat_in[7:0];
	// 				4'b1100: node.rc <= dat_in[7:0];
	// 				default: ;
	// 			endcase
	// 		end
	// 	end
	// end

	assign buffer = node;

endmodule

module bram_buffer_7 (
	input wire clk,
	input wire rst_p,
	input wire [31:0] dat_in,
	input wire [ 7:0] sel,
	input wire stb,
	input wire [305:0] node_in,
	output reg [305:0] buffer
);

	Node7 node;

	always_comb begin
		node = node_in;
		if (sel[7:2] == 6'd0) begin
			node.lc = dat_in[12:0];
		end else if (sel[7:2] == 6'd1) begin
			node.rc = dat_in[12:0];
		end else begin
			case (sel[3:2])
				2'd0: node.bin[sel[7:4] - 1].prefix_length = dat_in[4:0];
				2'd1: node.bin[sel[7:4] - 1].prefix = dat_in[27:0];
				2'd2: node.bin[sel[7:4] - 1].entry_offset = dat_in[4:0];
				default: ;
			endcase
		end
	end

	// always_ff @(posedge clk) begin
	// 	if (rst_p) begin
	// 		node <= 0;
	// 	end else begin
	// 		if (stb) begin
	// 			case (sel[3:0])
	// 				4'b0000: node.bin[sel[7:4]].prefix_length <= dat_in[4:0];
	// 				4'b0001: node.bin[sel[7:4]].prefix <= dat_in[27:0];
	// 				4'b0010: node.bin[sel[7:4]].entry_offset <= dat_in[4:0];
	// 				4'b1000: node.lc <= dat_in[12:0];
	// 				4'b1100: node.rc <= dat_in[12:0];
	// 				default: ;
	// 			endcase
	// 		end
	// 	end
	// end

	assign buffer = node;

endmodule

module bram_buffer_15 (
	input wire clk,
	input wire rst_p,
	input wire [31:0] dat_in,
	input wire [ 7:0] sel,
	input wire stb,
	input wire [611:0] node_in,
	output reg [611:0] buffer
);

	Node15 node;

	always_comb begin
		node = node_in;
		if (sel[7:2] == 6'd0) begin
			node.lc = dat_in[12:0];
		end else if (sel[7:2] == 6'd1) begin
			node.rc = dat_in[12:0];
		end else begin
			case (sel[3:2])
				2'd0: node.bin[sel[7:4] - 1].prefix_length = dat_in[4:0];
				2'd1: node.bin[sel[7:4] - 1].prefix = dat_in[27:0];
				2'd2: node.bin[sel[7:4] - 1].entry_offset = dat_in[4:0];
				default: ;
			endcase
		end
	end

	// always_ff @(posedge clk) begin
	// 	if (rst_p) begin
	// 		node <= 0;
	// 	end else begin
	// 		if (stb) begin
	// 			case (sel[3:0])
	// 				4'b0000: node.bin[sel[7:4]].prefix_length <= dat_in[4:0];
	// 				4'b0001: node.bin[sel[7:4]].prefix <= dat_in[27:0];
	// 				4'b0010: node.bin[sel[7:4]].entry_offset <= dat_in[4:0];
	// 				4'b1000: node.lc <= dat_in[7:0];
	// 				4'b1100: node.rc <= dat_in[7:0];
	// 				default: ;
	// 			endcase
	// 		end
	// 	end
	// end

	assign buffer = node;

endmodule

module bram_buffer_14 (
	input wire clk,
	input wire rst_p,
	input wire [31:0] dat_in,
	input wire [ 7:0] sel,
	input wire stb,
	input wire [557:0] node_in,
	output reg [557:0] buffer
);

	Node14 node;

	always_comb begin
		node = node_in;
		if (sel[7:2] == 6'd0) begin
			node.lc = dat_in[12:0];
		end else if (sel[7:2] == 6'd1) begin
			node.rc = dat_in[12:0];
		end else begin
			case (sel[3:2])
				2'd0: node.bin[sel[7:4] - 1].prefix_length = dat_in[4:0];
				2'd1: node.bin[sel[7:4] - 1].prefix = dat_in[27:0];
				2'd2: node.bin[sel[7:4] - 1].entry_offset = dat_in[4:0];
				default: ;
			endcase
		end
	end

	// always_ff @(posedge clk) begin
	// 	if (rst_p) begin
	// 		node <= 0;
	// 	end else begin
	// 		if (stb) begin
	// 			case (sel[3:0])
	// 				4'b0000: node.bin[sel[7:4]].prefix_length <= dat_in[4:0];
	// 				4'b0001: node.bin[sel[7:4]].prefix <= dat_in[27:0];
	// 				4'b0010: node.bin[sel[7:4]].entry_offset <= dat_in[4:0];
	// 				4'b1000: node.lc <= dat_in[7:0];
	// 				4'b1100: node.rc <= dat_in[7:0];
	// 				default: ;
	// 			endcase
	// 		end
	// 	end
	// end

	assign buffer = node;

endmodule

module bram_buffer_10 (
	input wire clk,
	input wire rst_p,
	input wire [31:0] dat_in,
	input wire [ 7:0] sel,
	input wire stb,
	input wire [413:0] node_in,
	output reg [413:0] buffer
);

	Node10 node;

	always_comb begin
		node = node_in;
		if (sel[7:2] == 6'd0) begin
			node.lc = dat_in[11:0];
		end else if (sel[7:2] == 6'd1) begin
			node.rc = dat_in[11:0];
		end else begin
			case (sel[3:2])
				2'd0: node.bin[sel[7:4] - 1].prefix_length = dat_in[4:0];
				2'd1: node.bin[sel[7:4] - 1].prefix = dat_in[27:0];
				2'd2: node.bin[sel[7:4] - 1].entry_offset = dat_in[4:0];
				default: ;
			endcase
		end
	end

	// always_ff @(posedge clk) begin
	// 	if (rst_p) begin
	// 		node <= 0;
	// 	end else begin
	// 		if (stb) begin
	// 			case (sel[3:0])
	// 				4'b0000: node.bin[sel[7:4]].prefix_length <= dat_in[4:0];
	// 				4'b0001: node.bin[sel[7:4]].prefix <= dat_in[27:0];
	// 				4'b0010: node.bin[sel[7:4]].entry_offset <= dat_in[4:0];
	// 				4'b1000: node.lc <= dat_in[7:0];
	// 				4'b1100: node.rc <= dat_in[7:0];
	// 				default: ;
	// 			endcase
	// 		end
	// 	end
	// end

	assign buffer = node;

endmodule
