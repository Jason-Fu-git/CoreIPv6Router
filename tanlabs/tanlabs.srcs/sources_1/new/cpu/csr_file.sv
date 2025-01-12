// @author: Jason Fu
`include "csrs.vh"

// 1. 读CSR寄存器要以组合逻辑实现
// 2. CSR寄存器的写数据为csr_data_i，需判断用户写入是否合法（写入的值是否为supported，以及是否修改了只读的值）
// ，不合法则设置csr_error_o为1。（注：对于WLRL无需报错，对于WARL可以直接忽略写入的非法值，详请参阅手册）
// 3. 无需维护 mtime 和 mtimecmp 寄存器

// begin @author: Yusaki
// 从监控程序看到需要用到的CSR寄存器：
// mtvec, mie, mscratch, satp, pmpcfg0, pmpaddr0, mepc, mstatus, mcause, mtval
//
// | satp | mstatus | mie | mtvec | mscratch | mepc | mcause | mtval | pmpcfg0 | pmpaddr0 |
// |------|---------|-----|-------|----------|------|--------|-------|---------|----------|
// | 180  | 300     | 304 | 305   | 340      | 341  | 342    | 343   | 3a0     | 3b0      |
//
// end @author

module csr_file (
    input wire clk_i,
    input wire rst_i,

    // address, input data
    input wire [11:0] csr_addr_i,
    input wire [31:0] csr_data_i,
    input wire csr_we_i,

    // output data
    output reg [31:0] csr_data_o,
    output reg        csr_error_o
);

  // 以下实现了一个没有访问控制的稀疏堆
  // TODO: Implement WLRL & WARL

  logic [31:0] satp, mstatus, mie, mip, mtvec, mscratch, mepc, mcause, mtval, pmpcfg0, pmpaddr0;

  always_comb begin
    case (csr_addr_i)
      CSR_SATP:     csr_data_o = satp;
      CSR_MSTATUS:  csr_data_o = mstatus;
      CSR_MIE:      csr_data_o = mie;
      CSR_MTVEC:    csr_data_o = mtvec;
      CSR_MSCRATCH: csr_data_o = mscratch;
      CSR_MEPC:     csr_data_o = mepc;
      CSR_MCAUSE:   csr_data_o = mcause;
      CSR_MTVAL:    csr_data_o = mtval;
      CSR_MIP:      csr_data_o = mip;
      CSR_PMPCFG0:  csr_data_o = pmpcfg0;
      CSR_PMPADDR0: csr_data_o = pmpaddr0;
      default:      csr_data_o = 0;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_i) begin
    if (rst_i) begin
      satp     <= 0;
      mstatus  <= 0;
      mie      <= 0;
      mip      <= 0;
      mtvec    <= 32'h80000000;
      mscratch <= 0;
      mepc     <= 0;
      mcause   <= 0;
      mtval    <= 0;
      pmpcfg0  <= 0;
      pmpaddr0 <= 0;
    end else begin
      if (csr_we_i) begin
        case (csr_addr_i)
          CSR_SATP:     satp <= csr_data_i;
          CSR_MSTATUS:  mstatus <= csr_data_i;
          CSR_MIE:      mie <= csr_data_i;
          CSR_MTVEC:    mtvec <= csr_data_i;
          CSR_MSCRATCH: mscratch <= csr_data_i;
          CSR_MEPC:     mepc <= csr_data_i;
          CSR_MCAUSE:   mcause <= csr_data_i;
          CSR_MTVAL:    mtval <= csr_data_i;
          CSR_MIP:      mip <= csr_data_i;
          CSR_PMPCFG0:  pmpcfg0 <= csr_data_i;
          CSR_PMPADDR0: pmpaddr0 <= csr_data_i;
          default:      ;
        endcase
      end
    end
  end

  assign csr_error_o = 0;

endmodule
