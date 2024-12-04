// LUT for the CLZ module
module clz_lut (
    input  wire [3:0] A,
    output reg  [5:0] Y
);

  always_comb begin : LUT
    case (A)
      4'b0000: Y = 6'd4;
      4'b0001: Y = 6'd3;
      4'b0010: Y = 6'd2;
      4'b0011: Y = 6'd2;
      4'b0100: Y = 6'd1;
      4'b0101: Y = 6'd1;
      4'b0110: Y = 6'd1;
      4'b0111: Y = 6'd1;
      4'b1000: Y = 6'd0;
      4'b1001: Y = 6'd0;
      4'b1010: Y = 6'd0;
      4'b1011: Y = 6'd0;
      4'b1100: Y = 6'd0;
      4'b1101: Y = 6'd0;
      4'b1110: Y = 6'd0;
      4'b1111: Y = 6'd0;
      default: Y = 6'd0;
    endcase
  end

endmodule
