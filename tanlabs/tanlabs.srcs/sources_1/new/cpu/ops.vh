`ifndef OPS_VH_H
`define OPS_VH_H

 // 操作符定义
 parameter ALU_NOP = 5'd0;
 parameter ALU_ADD = 5'd1;
 parameter ALU_SUB = 5'd2;
 parameter ALU_AND = 5'd3;
 parameter ALU_OR  = 5'd4;
 parameter ALU_XOR = 5'd5;
 parameter ALU_NOT = 5'd6;
 parameter ALU_SLL = 5'd7;
 parameter ALU_SRL = 5'd8;
 parameter ALU_SRA = 5'd9;
 parameter ALU_ROL = 5'd10;
 parameter ALU_SLT = 5'd11;
 parameter ALU_SLTU= 5'd12;
 parameter ALU_PCNT= 5'd13;
 parameter ALU_CLZ = 5'd14;
 parameter ALU_GRV = 5'd15;
 parameter ALU_BREV8 = 5'd16;

 parameter OP_NOP  = 6'd0;
 parameter OP_LUI  = 6'd1;
 parameter OP_AUIPC= 6'd2;
 parameter OP_JAL  = 6'd3;
 parameter OP_JALR = 6'd4;
 parameter OP_BEQ  = 6'd5;
 parameter OP_BNE  = 6'd6;
 parameter OP_BLT  = 6'd7;
 parameter OP_BGE  = 6'd8;
 parameter OP_BLTU = 6'd9;
 parameter OP_BGEU = 6'd10;
 parameter OP_LB   = 6'd11;
 parameter OP_LH   = 6'd12;
 parameter OP_LW   = 6'd13;
 parameter OP_LBU  = 6'd14;
 parameter OP_LHU  = 6'd15;
 parameter OP_SB   = 6'd16;
 parameter OP_SH   = 6'd17;
 parameter OP_SW   = 6'd18;
 parameter OP_ADDI = 6'd19;
 parameter OP_SLTI = 6'd20;
 parameter OP_SLTIU= 6'd21;
 parameter OP_XORI = 6'd22;
 parameter OP_ORI  = 6'd23;
 parameter OP_ANDI = 6'd24;
 parameter OP_SLLI = 6'd25;
 parameter OP_SRLI = 6'd26;
 parameter OP_SRAI = 6'd27;
 parameter OP_ADD  = 6'd28;
 parameter OP_SUB  = 6'd29;
 parameter OP_SLL  = 6'd30;
 parameter OP_SLT  = 6'd31;
 parameter OP_SLTU = 6'd32;
 parameter OP_XOR  = 6'd33;
 parameter OP_SRL  = 6'd34;
 parameter OP_SRA  = 6'd35;
 parameter OP_OR   = 6'd36;
 parameter OP_AND  = 6'd37;
 parameter OP_FENCE= 6'd38;
 parameter OP_FENCE_I= 6'd39;
 parameter OP_ECALL= 6'd40;
 parameter OP_EBREAK= 6'd41;
 parameter OP_CSRRW= 6'd42;
 parameter OP_CSRRS= 6'd43;
 parameter OP_CSRRC= 6'd44;
 parameter OP_CSRRWI= 6'd45;
 parameter OP_CSRRSI= 6'd46;
 parameter OP_CSRRCI= 6'd47;
 parameter OP_PCNT = 6'd48;
 parameter OP_CLZ  = 6'd49;
 parameter OP_PACK = 6'd50;
 parameter OP_MRET = 6'd51;
 parameter OP_GREVI = 6'd53;
 parameter OP_BREV8= 6'd54;


`endif



