`timescale 1ns / 1ps

module bram_controller #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 54
)(
	input wire clk,
	input wire rst_p,
	input wire stb_i,
	input wire [ADDR_WIDTH-1:0] adr_i,
	input wire [DATA_WIDTH-1:0] dat_i,
	output reg [DATA_WIDTH-1:0] dat_o,
	input wire wea_i,
	output reg ack_o,

	output reg [ADDR_WIDTH-1:0] bram_adr,
	output reg [DATA_WIDTH-1:0] bram_dat_out,
	input wire [DATA_WIDTH-1:0] bram_dat_in,
	output reg bram_wea
);

	assign bram_adr = adr_i;
	assign bram_dat_out = dat_i;
	assign dat_o = bram_dat_in;

	logic writing;
	logic ack_o_reg;

	always_ff @(posedge clk) begin
		if (rst_p) begin
			ack_o_reg <= 0;
			dat_o <= 0;
			bram_adr <= 0;
			bram_dat_out <= 0;
			bram_wea <= 0;
			reading <= 0;
			writing <= 0;
		end else begin
			if (stb_i) begin
				if (wea_i && !writing) begin
					writing <= 1;
					bram_wea <= 1;
				end else begin
					ack_o_reg <= 1;
					writing <= 0;
				end
			end
		end
	end

	assign ack_o = ack_o_reg && stb_i;

endmodule : bram_controller
