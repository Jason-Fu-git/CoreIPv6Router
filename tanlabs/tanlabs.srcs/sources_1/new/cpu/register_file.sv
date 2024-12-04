// @author: Jason Fu
module register_file (
    input wire clk,  // 时钟
    input wire rst,  // 同步复位

    input wire [4:0] rf_raddr_a,  // 读A地址
    input wire [4:0] rf_raddr_b,  // 读B地址
    input wire [4:0] rf_waddr,    // 写地址

    input wire [31:0] rf_wdata,  // 待写的数据

    output reg [31:0] rf_rdata_a,  // A的数据
    output reg [31:0] rf_rdata_b,  // B的数据

    input wire rf_we_p,  // 写使能
    output reg errno  // 错误标志
);

  // 32个寄存器
  reg [31:0] x0;
  reg [31:0] x1;
  reg [31:0] x2;
  reg [31:0] x3;
  reg [31:0] x4;
  reg [31:0] x5;
  reg [31:0] x6;
  reg [31:0] x7;
  reg [31:0] x8;
  reg [31:0] x9;
  reg [31:0] x10;
  reg [31:0] x11;
  reg [31:0] x12;
  reg [31:0] x13;
  reg [31:0] x14;
  reg [31:0] x15;
  reg [31:0] x16;
  reg [31:0] x17;
  reg [31:0] x18;
  reg [31:0] x19;
  reg [31:0] x20;
  reg [31:0] x21;
  reg [31:0] x22;
  reg [31:0] x23;
  reg [31:0] x24;
  reg [31:0] x25;
  reg [31:0] x26;
  reg [31:0] x27;
  reg [31:0] x28;
  reg [31:0] x29;
  reg [31:0] x30;
  reg [31:0] x31;

  // ===== 组合逻辑部分 =====
  always_comb begin : Read
    // 输出rs1
    case (rf_raddr_a)
      5'd0: rf_rdata_a = x0;
      5'd1: rf_rdata_a = x1;
      5'd2: rf_rdata_a = x2;
      5'd3: rf_rdata_a = x3;
      5'd4: rf_rdata_a = x4;
      5'd5: rf_rdata_a = x5;
      5'd6: rf_rdata_a = x6;
      5'd7: rf_rdata_a = x7;
      5'd8: rf_rdata_a = x8;
      5'd9: rf_rdata_a = x9;
      5'd10: rf_rdata_a = x10;
      5'd11: rf_rdata_a = x11;
      5'd12: rf_rdata_a = x12;
      5'd13: rf_rdata_a = x13;
      5'd14: rf_rdata_a = x14;
      5'd15: rf_rdata_a = x15;
      5'd16: rf_rdata_a = x16;
      5'd17: rf_rdata_a = x17;
      5'd18: rf_rdata_a = x18;
      5'd19: rf_rdata_a = x19;
      5'd20: rf_rdata_a = x20;
      5'd21: rf_rdata_a = x21;
      5'd22: rf_rdata_a = x22;
      5'd23: rf_rdata_a = x23;
      5'd24: rf_rdata_a = x24;
      5'd25: rf_rdata_a = x25;
      5'd26: rf_rdata_a = x26;
      5'd27: rf_rdata_a = x27;
      5'd28: rf_rdata_a = x28;
      5'd29: rf_rdata_a = x29;
      5'd30: rf_rdata_a = x30;
      5'd31: rf_rdata_a = x31;
      default: rf_rdata_a = 0;
    endcase
    // 输出rs2
    case (rf_raddr_b)
      5'd0: rf_rdata_b = x0;
      5'd1: rf_rdata_b = x1;
      5'd2: rf_rdata_b = x2;
      5'd3: rf_rdata_b = x3;
      5'd4: rf_rdata_b = x4;
      5'd5: rf_rdata_b = x5;
      5'd6: rf_rdata_b = x6;
      5'd7: rf_rdata_b = x7;
      5'd8: rf_rdata_b = x8;
      5'd9: rf_rdata_b = x9;
      5'd10: rf_rdata_b = x10;
      5'd11: rf_rdata_b = x11;
      5'd12: rf_rdata_b = x12;
      5'd13: rf_rdata_b = x13;
      5'd14: rf_rdata_b = x14;
      5'd15: rf_rdata_b = x15;
      5'd16: rf_rdata_b = x16;
      5'd17: rf_rdata_b = x17;
      5'd18: rf_rdata_b = x18;
      5'd19: rf_rdata_b = x19;
      5'd20: rf_rdata_b = x20;
      5'd21: rf_rdata_b = x21;
      5'd22: rf_rdata_b = x22;
      5'd23: rf_rdata_b = x23;
      5'd24: rf_rdata_b = x24;
      5'd25: rf_rdata_b = x25;
      5'd26: rf_rdata_b = x26;
      5'd27: rf_rdata_b = x27;
      5'd28: rf_rdata_b = x28;
      5'd29: rf_rdata_b = x29;
      5'd30: rf_rdata_b = x30;
      5'd31: rf_rdata_b = x31;
      default: rf_rdata_b = 0;
    endcase
  end

  // ===== 时序逻辑部分 =====
  always_ff @(posedge clk) begin : Write
    if (rst) begin
      // 重置所有的寄存器
      x0 <= 0;
      x1 <= 0;
      x2 <= 0;
      x3 <= 0;
      x4 <= 0;
      x5 <= 0;
      x6 <= 0;
      x7 <= 0;
      x8 <= 0;
      x9 <= 0;
      x10 <= 0;
      x11 <= 0;
      x12 <= 0;
      x13 <= 0;
      x14 <= 0;
      x15 <= 0;
      x16 <= 0;
      x17 <= 0;
      x18 <= 0;
      x19 <= 0;
      x20 <= 0;
      x21 <= 0;
      x22 <= 0;
      x23 <= 0;
      x24 <= 0;
      x25 <= 0;
      x26 <= 0;
      x27 <= 0;
      x28 <= 0;
      x29 <= 0;
      x30 <= 0;
      x31 <= 0;
    end else begin
      // 写使能
      if (rf_we_p == 1'b1) begin
        case (rf_waddr)
          // 5'd0 : x0 <= rf_wdata; x0 只读
          5'd1: x1 <= rf_wdata;
          5'd2: x2 <= rf_wdata;
          5'd3: x3 <= rf_wdata;
          5'd4: x4 <= rf_wdata;
          5'd5: x5 <= rf_wdata;
          5'd6: x6 <= rf_wdata;
          5'd7: x7 <= rf_wdata;
          5'd8: x8 <= rf_wdata;
          5'd9: x9 <= rf_wdata;
          5'd10: x10 <= rf_wdata;
          5'd11: x11 <= rf_wdata;
          5'd12: x12 <= rf_wdata;
          5'd13: x13 <= rf_wdata;
          5'd14: x14 <= rf_wdata;
          5'd15: x15 <= rf_wdata;
          5'd16: x16 <= rf_wdata;
          5'd17: x17 <= rf_wdata;
          5'd18: x18 <= rf_wdata;
          5'd19: x19 <= rf_wdata;
          5'd20: x20 <= rf_wdata;
          5'd21: x21 <= rf_wdata;
          5'd22: x22 <= rf_wdata;
          5'd23: x23 <= rf_wdata;
          5'd24: x24 <= rf_wdata;
          5'd25: x25 <= rf_wdata;
          5'd26: x26 <= rf_wdata;
          5'd27: x27 <= rf_wdata;
          5'd28: x28 <= rf_wdata;
          5'd29: x29 <= rf_wdata;
          5'd30: x30 <= rf_wdata;
          5'd31: x31 <= rf_wdata;
          default: errno <= 1;
        endcase
      end
    end
  end


  // ========================

endmodule
