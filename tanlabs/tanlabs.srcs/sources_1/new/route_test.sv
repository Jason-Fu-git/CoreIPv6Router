typedef struct {
	logic [127:0] prefix;
	logic [127:0] next_hop;
	logic [  7:0] length;
} VCEntry;

typedef struct {
	logic   [31:0] l_offset;
	logic   [31:0] r_offset;
	BTEntry [ 3:0] bin;
} VCNode;

module routelookup#(
	parameter MAX_LEVEL = 4'd8
)(
	input  wire          clk,
	input  wire          rst_p,
	input  logic [127:0] prefix_i,
	input  logic [127:0] next_hop_i,
	input  logic [ 31:0] base_addr_i,
	input  logic [  7:0] longest_match_i,
	input  logic [  7:0] level_i,
	input  logic         stb_i,
	output logic [127:0] prefix_o,
	output logic [127:0] next_hop_o,
	output logic [ 31:0] base_addr_o,
	output logic [  7:0] longest_match_o,
	output logic [  7:0] level_o,
	output logic         ack_o
);
	
	

endmodule : routelookup
