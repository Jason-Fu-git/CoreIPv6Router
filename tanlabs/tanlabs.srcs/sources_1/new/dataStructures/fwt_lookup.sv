`timescale 1ns / 1ps

module fwt_lookup(
    input  wire [  4:0] in,
    output reg  [127:0] out,
    output reg  [  1:0] out_iface
);

    always_comb begin
        case (in)
            5'b00000: out = 128'h011069feff641f8e00000000000080fe; // fe80::8e1f:64ff:fe69:1001
            5'b00001: out = 128'h021069feff641f8e00000000000080fe; // fe80::8e1f:64ff:fe69:1002
            5'b00010: out = 128'h031069feff641f8e00000000000080fe; // fe80::8e1f:64ff:fe69:1003
            5'b00011: out = 128'h041069feff641f8e00000000000080fe; // fe80::8e1f:64ff:fe69:1004
            default : out = 0;
        endcase
        out_iface = in[1:0];
    end

endmodule
