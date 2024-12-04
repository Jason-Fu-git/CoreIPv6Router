`default_nettype none
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
  // PCNT : count the number of 1 in A
  // =====================================
  logic [5:0]
      ALU_PCNT_4,
      ALU_PCNT_3_1,
      ALU_PCNT_3_0,
      ALU_PCNT_2_3,
      ALU_PCNT_2_2,
      ALU_PCNT_2_1,
      ALU_PCNT_2_0,
      ALU_PCNT_1_7,
      ALU_PCNT_1_6,
      ALU_PCNT_1_5,
      ALU_PCNT_1_4,
      ALU_PCNT_1_3,
      ALU_PCNT_1_2,
      ALU_PCNT_1_1,
      ALU_PCNT_1_0;

  assign ALU_PCNT_2_0 = ALU_PCNT_1_0 + ALU_PCNT_1_1;
  assign ALU_PCNT_2_1 = ALU_PCNT_1_2 + ALU_PCNT_1_3;
  assign ALU_PCNT_2_2 = ALU_PCNT_1_4 + ALU_PCNT_1_5;
  assign ALU_PCNT_2_3 = ALU_PCNT_1_6 + ALU_PCNT_1_7;

  assign ALU_PCNT_3_0 = ALU_PCNT_2_0 + ALU_PCNT_2_1;
  assign ALU_PCNT_3_1 = ALU_PCNT_2_2 + ALU_PCNT_2_3;

  assign ALU_PCNT_4   = ALU_PCNT_3_0 + ALU_PCNT_3_1;


  // =====================================
  // CLZ : count the number of leading zeros in A
  // =====================================
  logic [5:0]
      ALU_CLZ_4,
      ALU_CLZ_3_1,
      ALU_CLZ_3_0,
      ALU_CLZ_2_3,
      ALU_CLZ_2_2,
      ALU_CLZ_2_1,
      ALU_CLZ_2_0,
      ALU_CLZ_1_7,
      ALU_CLZ_1_6,
      ALU_CLZ_1_5,
      ALU_CLZ_1_4,
      ALU_CLZ_1_3,
      ALU_CLZ_1_2,
      ALU_CLZ_1_1,
      ALU_CLZ_1_0;


  assign ALU_CLZ_2_0 = (ALU_CLZ_1_0 != 6'd4) ? ALU_CLZ_1_0 : (ALU_CLZ_1_0 + ALU_CLZ_1_1);
  assign ALU_CLZ_2_1 = (ALU_CLZ_1_2 != 6'd4) ? ALU_CLZ_1_2 : (ALU_CLZ_1_2 + ALU_CLZ_1_3);
  assign ALU_CLZ_2_2 = (ALU_CLZ_1_4 != 6'd4) ? ALU_CLZ_1_4 : (ALU_CLZ_1_4 + ALU_CLZ_1_5);
  assign ALU_CLZ_2_3 = (ALU_CLZ_1_6 != 6'd4) ? ALU_CLZ_1_6 : (ALU_CLZ_1_6 + ALU_CLZ_1_7);

  assign ALU_CLZ_3_0 = (ALU_CLZ_2_0 != 6'd8) ? ALU_CLZ_2_0 : (ALU_CLZ_2_0 + ALU_CLZ_2_1);
  assign ALU_CLZ_3_1 = (ALU_CLZ_2_2 != 6'd8) ? ALU_CLZ_2_2 : (ALU_CLZ_2_2 + ALU_CLZ_2_3);

  assign ALU_CLZ_4   = (ALU_CLZ_3_0 != 6'd16) ? ALU_CLZ_3_0 : (ALU_CLZ_3_0 + ALU_CLZ_3_1);

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
      ALU_PCNT: Y = ALU_PCNT_4;
      ALU_CLZ:  Y = ALU_CLZ_4;
      default:  Y = 32'b0;
    endcase
  end


  pcnt_lut pcnt_lut_0 (
      .A(A[3:0]),
      .Y(ALU_PCNT_1_0)
  );

  pcnt_lut pcnt_lut_1 (
      .A(A[7:4]),
      .Y(ALU_PCNT_1_1)
  );

  pcnt_lut pcnt_lut_2 (
      .A(A[11:8]),
      .Y(ALU_PCNT_1_2)
  );

  pcnt_lut pcnt_lut_3 (
      .A(A[15:12]),
      .Y(ALU_PCNT_1_3)
  );

  pcnt_lut pcnt_lut_4 (
      .A(A[19:16]),
      .Y(ALU_PCNT_1_4)
  );

  pcnt_lut pcnt_lut_5 (
      .A(A[23:20]),
      .Y(ALU_PCNT_1_5)
  );

  pcnt_lut pcnt_lut_6 (
      .A(A[27:24]),
      .Y(ALU_PCNT_1_6)
  );

  pcnt_lut pcnt_lut_7 (
      .A(A[31:28]),
      .Y(ALU_PCNT_1_7)
  );

  clz_lut clz_lut_0 (
      .A(A[31:28]),
      .Y(ALU_CLZ_1_0)
  );

  clz_lut clz_lut_1 (
      .A(A[27:24]),
      .Y(ALU_CLZ_1_1)
  );

  clz_lut clz_lut_2 (
      .A(A[23:20]),
      .Y(ALU_CLZ_1_2)
  );

  clz_lut clz_lut_3 (
      .A(A[19:16]),
      .Y(ALU_CLZ_1_3)
  );

  clz_lut clz_lut_4 (
      .A(A[15:12]),
      .Y(ALU_CLZ_1_4)
  );

  clz_lut clz_lut_5 (
      .A(A[11:8]),
      .Y(ALU_CLZ_1_5)
  );

  clz_lut clz_lut_6 (
      .A(A[7:4]),
      .Y(ALU_CLZ_1_6)
  );

  clz_lut clz_lut_7 (
      .A(A[3:0]),
      .Y(ALU_CLZ_1_7)
  );


endmodule
