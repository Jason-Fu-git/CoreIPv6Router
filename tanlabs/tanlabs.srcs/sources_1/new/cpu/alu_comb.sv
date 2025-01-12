`include "ops.vh"

// 简单的ALU实现
// @author : Jason Fu
module alu_comb (
    input  wire [31:0] A,   // 32 位输入数据
    input  wire [31:0] B,   // 32 位输入数据
    input  wire [ 4:0] OP,  // 操作码
    output reg  [31:0] Y    // 32 位输出数据
);

  // =====================================
  // ALU operation
  // =====================================
  logic [63:0] temp;
  logic [31:0] temp32;
  always_comb begin : ALU
    case (OP)
      ALU_ADD:  Y = A + B;
      ALU_SUB:  Y = A - B;
      ALU_AND:  Y = A & B;
      ALU_OR:   Y = A | B;
      ALU_XOR:  Y = A ^ B;
      ALU_NOT:  Y = ~A;
      ALU_SLL:  Y = A << B[4:0];
      ALU_SRL:  Y = A >> B[4:0];
      ALU_SRA:  Y = $signed(A) >>> B[4:0];
      ALU_ROL: begin
        temp = {A, A} << B[4:0];
        Y = temp[63:32];
      end
      ALU_SLT:  Y = $signed(A) < $signed(B);
      ALU_SLTU: Y = A < B;
      ALU_GRV: begin
        temp32 = A;
        if (B[0]) temp32 = ((temp32 & 32'h5555_5555) << 1) | ((temp32 & 32'hAAAA_AAAA) >> 1);
        if (B[1]) temp32 = ((temp32 & 32'h3333_3333) << 2) | ((temp32 & 32'hCCCC_CCCC) >> 2);
        if (B[2]) temp32 = ((temp32 & 32'h0F0F_0F0F) << 4) | ((temp32 & 32'hF0F0_F0F0) >> 4);
        if (B[3]) temp32 = ((temp32 & 32'h00FF_00FF) << 8) | ((temp32 & 32'hFF00_FF00) >> 8);
        if (B[4]) temp32 = ((temp32 & 32'h0000_FFFF) << 16) | ((temp32 & 32'hFFFF_0000) >> 16);
        Y = temp32;
      end
      ALU_BREV8: begin
        for (int j = 0; j < 4; j++) begin
          for (int i = 0; i < 8; i++) begin
            Y[8*j+i] = A[8*j+7-i];
          end
        end
      end
      default:  Y = 32'b0;
    endcase
  end

endmodule
