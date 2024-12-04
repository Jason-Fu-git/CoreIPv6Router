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
      default:  Y = 32'b0;
    endcase
  end

endmodule
