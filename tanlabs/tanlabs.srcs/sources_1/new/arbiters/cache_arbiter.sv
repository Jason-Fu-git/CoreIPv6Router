`timescale 1ns / 1ps

`include "frame_datapath.vh"

module cache_arbiter(
    input wire clk,
    input wire rst_p,
    input wire ns_valid,
    input wire na_valid,
    input cache_entry ns_in,
    input cache_entry na_in,
    output reg ns_ready,
    output reg na_ready,
    output cache_entry out,
    output reg wea_p
);

    assign ns_ready = 1'b1;
    assign na_ready = !ns_valid;
    assign out = ns_valid ? ns_in : (na_valid ? na_in : 0);
    assign wea_p = ns_valid || na_valid;

endmodule
