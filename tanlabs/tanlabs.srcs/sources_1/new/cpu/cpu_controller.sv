// CPU Controller Implemented with 5-stage Pipeline
// @author : Jason Fu
`include "ops.vh"
`include "exceptions.vh"
`include "csrs.vh"


module cpu_controller (
    input wire clk,
    input wire rst_p, // 同步复位

    // Register File Interface
    output reg  [ 4:0] rf_raddr_a,  // RF port A address
    output reg  [ 4:0] rf_raddr_b,  // RF port B address
    input  wire [31:0] rf_rdata_a,  // RF port A data
    input  wire [31:0] rf_rdata_b,  // RF port B data
    output reg  [ 4:0] rf_waddr,    // RF write address
    output reg  [31:0] rf_wdata,    // RF write data
    output reg         rf_we_p,     // RF write enable

    // CSR File Interface
    output reg  [11:0] csr_addr_o,
    output reg  [31:0] csr_data_o,
    output reg         csr_we_o,
    // output data
    input  wire [31:0] csr_data_i,
    input  wire        csr_error_i,

    // ALU Interface
    output reg  [31:0] alu_a,   // ALU input A
    output reg  [31:0] alu_b,   // ALU input B
    output reg  [ 4:0] alu_op,  // ALU opcode
    input  wire [31:0] alu_y,   // ALU output

    // Data Memory Interface & Wishbone
    output reg  [31:0] dm_adr_o,  // ADR_O() address output
    output reg  [31:0] dm_dat_o,  // DAT_O() data out
    input  wire [31:0] dm_dat_i,  // DAT_I() data in
    output reg         dm_we_o,   // WE_O write enable output
    output reg  [ 3:0] dm_sel_o,  // SEL_O() select output
    output reg         dm_stb_o,  // STB_O strobe output
    input  wire        dm_ack_i,  // ACK_I acknowledge input
    input  wire        dm_err_i,  // ERR_I error input
    input  wire        dm_rty_i,  // RTY_I retry input
    output reg         dm_cyc_o,  // CYC_O cycle output

    // Instruction Memory Interface
    output reg  [31:0] im_adr_o,
    output reg  [31:0] im_dat_o,
    input  wire [31:0] im_dat_i,
    output reg         im_we_o,
    output reg  [ 3:0] im_sel_o,
    output reg         im_stb_o,
    input  wire        im_ack_i,
    input  wire        im_err_i,
    input  wire        im_rty_i,
    output reg         im_cyc_o,

    // fence
    output reg im_fence_o,
    output reg dm_fence_o,

    // BTB Interface
    output reg  [31:0] btb_if_pc,
    output reg  [31:0] btb_id_pc,
    output reg  [31:0] btb_id_offset,
    output reg         btb_id_bc,
    output reg         btb_id_we,
    input  wire [31:0] btb_pred_pc,
    input  wire        btb_pred_bc
);

  // =====================================
  // Naming
  // if_ready: means if.out_ready, also means IF/ID Reg is ready to accept new data
  // if_flush: means IF/ID Reg is going to be flushed
  // if_xxx:   means the data in IF/ID Reg
  // =====================================

  privilege_t        privilege;
  logic       [63:0] mtime;
  logic       [63:0] mtimecmp;

  // =====================================
  // Pipeline Signals
  // =====================================

  logic              if_ready;
  logic              id_ready;
  logic              ex_ready;
  logic              mem_ready;
  logic              wb_ready;

  logic              if_valid;
  logic              id_valid;
  logic              ex_valid;
  logic              mem_valid;

  logic              if_flush;
  logic              id_flush;
  logic              ex_flush;

  // =====================================
  // Pipeline registers
  // =====================================

  // PC
  logic       [31:0] pc;
  logic       [31:0] pc_next;

  logic       [31:0] if_pc;
  logic       [31:0] id_pc;
  logic       [31:0] ex_pc;
  logic       [31:0] mem_pc;

  // ops
  logic       [ 5:0] id_op;
  logic       [ 5:0] ex_op;
  logic       [ 5:0] mem_op;

  // rd address
  reg         [ 4:0] id_rd;
  reg         [ 4:0] ex_rd;
  reg         [ 4:0] mem_rd;

  // rs1 address
  reg         [ 4:0] id_rs1;

  // rs2 address
  reg         [ 4:0] id_rs2;
  reg         [ 4:0] ex_rs2;

  // csr address
  reg         [11:0] id_csr;
  reg         [11:0] ex_csr;
  reg         [11:0] mem_csr;

  // rs1 data
  reg         [31:0] id_rs1_dat;

  // rs2 data
  reg         [31:0] id_rs2_dat;
  reg         [31:0] ex_rs2_dat;

  // imm
  logic       [31:0] id_imm;
  logic       [31:0] ex_imm;
  logic       [31:0] mem_imm;


  // branch condition (=1 means branch taken)
  logic              id_bc;


  // branch prediction (=1 means branch taken)
  logic              id_bp;


  // mem load signals
  logic              id_mem_load;
  logic              ex_mem_load;
  logic              mem_mem_load;

  // mem store signals
  logic              id_mem_store;
  logic              ex_mem_store;
  logic              mem_mem_store;

  // mem csr signals
  logic              id_mem_csr;
  logic              ex_mem_csr;
  logic              mem_mem_csr;

  // exception signals
  exception_t        if_ec;
  exception_t        id_ec;
  exception_t        ex_ec;
  exception_t        mem_ec;

  // id decode signals
  logic       [ 5:0] id_op_next;
  logic       [11:0] id_csr_next;
  logic       [31:0] id_imm_next;


  // IDLE
  logic              mem_idle;
  logic              if_idle;

  // EXCEPTION
  logic              exception;
  logic              exception_reg;  // exception in the previous cycle, for successfully setting pc


  // =====================================
  // Forwarding
  // =====================================

  // Regs to be forwarded
  logic              ex_forward_valid;
  logic              mem_forward_valid;


  // Regs used in ID, EX, MEM
  logic       [31:0] id_rs1_fwd;
  logic              id_rs1_ea;  // whether rs1 data is used in ID
  logic       [31:0] id_rs2_fwd;
  logic              id_rs2_ea;

  logic       [31:0] ex_rs1_fwd;
  logic       [31:0] ex_rs2_fwd;

  logic              id_ex_rs1_ea;
  logic              id_ex_rs2_ea;
  logic              ex_rs1_ea;
  logic              ex_rs2_ea;

  logic       [31:0] mem_rs2_fwd;

  logic              id_mem_rs2_ea;
  logic              ex_mem_rs2_ea;
  logic              mem_rs2_ea;


  // Data hazard detection
  logic              id_rs1_data_hazard;
  logic              id_rs2_data_hazard;
  logic              ex_rs1_data_hazard;
  logic              ex_rs2_data_hazard;
  logic              mem_data_hazard;

  logic              data_hazard;

  assign data_hazard = id_rs1_data_hazard
                    || id_rs2_data_hazard
                    || ex_rs1_data_hazard
                    || ex_rs2_data_hazard
                    || mem_data_hazard;


  always_comb begin : ID_RS1_DATA_HAZARD
    id_rs1_data_hazard = 0;
    id_rs1_fwd         = rf_rdata_a;
    // rs1
    if (rf_raddr_a != 0) begin
      if (rf_raddr_a == id_rd) begin  // ID
        id_rs1_data_hazard = (id_rs1_ea) ? 1 : 0;
      end else if (rf_raddr_a == ex_rd) begin  // EX
        if (ex_forward_valid) begin
          id_rs1_data_hazard = 0;
          id_rs1_fwd         = ex_imm;
        end else begin
          id_rs1_data_hazard = (id_rs1_ea) ? 1 : 0;
        end
      end else if (rf_raddr_a == mem_rd) begin  // MEM
        if (mem_forward_valid) begin
          id_rs1_data_hazard = 0;
          id_rs1_fwd         = mem_imm;
        end else begin
          id_rs1_data_hazard = (id_rs1_ea) ? 1 : 0;
        end
      end
    end
  end

  always_comb begin : ID_RS2_DATA_HAZARD
    id_rs2_data_hazard = 0;
    id_rs2_fwd         = rf_rdata_b;
    // rs2
    if (rf_raddr_b != 0) begin
      if (rf_raddr_b == id_rd) begin  // ID
        id_rs2_data_hazard = (id_rs2_ea) ? 1 : 0;
      end else if (rf_raddr_b == ex_rd) begin  // EX
        if (ex_forward_valid) begin
          id_rs2_data_hazard = 0;
          id_rs2_fwd         = ex_imm;
        end else begin
          id_rs2_data_hazard = (id_rs2_ea) ? 1 : 0;
        end
      end else if (rf_raddr_b == mem_rd) begin  // MEM
        if (mem_forward_valid) begin
          id_rs2_data_hazard = 0;
          id_rs2_fwd         = mem_imm;
        end else begin
          id_rs2_data_hazard = (id_rs2_ea) ? 1 : 0;
        end
      end
    end
  end


  always_comb begin : EX_RS1_DATA_HAZARD
    ex_rs1_data_hazard = 0;
    ex_rs1_fwd         = id_rs1_dat;
    if (id_rs1 != 0) begin
      if (id_rs1 == ex_rd) begin
        if (ex_forward_valid) begin
          ex_rs1_data_hazard = 0;
          ex_rs1_fwd         = ex_imm;
        end else begin
          ex_rs1_data_hazard = (ex_rs1_ea) ? 1 : 0;
        end
      end else if (id_rs1 == mem_rd) begin
        if (mem_forward_valid) begin
          ex_rs1_data_hazard = 0;
          ex_rs1_fwd         = mem_imm;
        end else begin
          ex_rs1_data_hazard = (ex_rs1_ea) ? 1 : 0;
        end
      end
    end
  end

  always_comb begin : EX_RS2_DATA_HAZARD
    ex_rs2_data_hazard = 0;
    ex_rs2_fwd         = id_rs2_dat;
    if (id_rs2 != 0) begin
      if (id_rs2 == ex_rd) begin
        if (ex_forward_valid) begin
          ex_rs2_data_hazard = 0;
          ex_rs2_fwd         = ex_imm;
        end else begin
          ex_rs2_data_hazard = (ex_rs2_ea) ? 1 : 0;
        end
      end else if (id_rs2 == mem_rd) begin
        if (mem_forward_valid) begin
          ex_rs2_data_hazard = 0;
          ex_rs2_fwd         = mem_imm;
        end else begin
          ex_rs2_data_hazard = (ex_rs2_ea) ? 1 : 0;
        end
      end
    end
  end


  always_comb begin : MEM_DATA_HAZARD
    mem_data_hazard = 0;
    mem_rs2_fwd     = ex_rs2_dat;
    // rs2
    if (ex_rs2 > 0) begin
      if (ex_rs2 == mem_rd) begin
        if (mem_forward_valid) begin
          mem_data_hazard = 0;
          mem_rs2_fwd     = mem_imm;
        end else begin
          mem_data_hazard = (mem_rs2_ea) ? 1 : 0;
        end
      end
    end
  end


  // =====================================
  // Fence.I
  // =====================================

  // State Machine
  typedef enum logic [1:0] {
    CPU_FENCE_IDLE,
    CPU_FENCE_WAIT,
    CPU_FENCE_SENT,
    CPU_FENCE_DONE
  } cpu_fence_state_t;
  cpu_fence_state_t cpu_fence_state;

  always_ff @(posedge clk) begin : CPU_FENCE
    if (rst_p) begin
      cpu_fence_state <= CPU_FENCE_IDLE;
      im_fence_o <= 0;
      dm_fence_o <= 0;
    end else begin
      case (cpu_fence_state)
        CPU_FENCE_IDLE: begin
          if (id_op_next == OP_FENCE_I && !exception) begin
            cpu_fence_state <= CPU_FENCE_WAIT;
          end
          im_fence_o <= 0;
          dm_fence_o <= 0;
        end
        CPU_FENCE_WAIT: begin
          // Wait for all memory stages to be idle
          if (mem_idle && (!mem_mem_load) && (!mem_mem_store) && if_idle) begin
            cpu_fence_state <= CPU_FENCE_SENT;
            im_fence_o <= 1;
            dm_fence_o <= 1;
          end
        end
        CPU_FENCE_SENT: begin
          if (im_ack_i) begin
            im_fence_o <= 0;
          end
          if (dm_ack_i) begin
            dm_fence_o <= 0;
          end
          // Wait for all fence signals to be de-asserted
          if (im_fence_o == 0 && dm_fence_o == 0) begin
            cpu_fence_state <= CPU_FENCE_DONE;
          end
        end
        CPU_FENCE_DONE: begin
          cpu_fence_state <= CPU_FENCE_IDLE;
        end
        default: cpu_fence_state <= CPU_FENCE_IDLE;
      endcase
    end
  end


  // =====================================
  // Instruction Fetch
  // =====================================
  reg   [31:0] im_dat_i_reg;
  reg   [31:0] if_instr;

  // =============
  // PC & NPC
  // =============

  // flush
  logic        if_flush_reg;
  always_ff @(posedge clk) begin : IF_FLUSH_REG
    if (rst_p) begin
      if_flush_reg <= 0;
    end else begin
      if_flush_reg <= if_flush;
    end
  end

  always_comb begin : IF_FLUSH
    if (if_flush_reg) begin
      // Wait for IF to be idle and fence to be done
      if (
            !if_idle
            || (cpu_fence_state == CPU_FENCE_WAIT)
            || (cpu_fence_state == CPU_FENCE_SENT)
            || exception
         ) begin
        if_flush = 1;
      end else begin
        if_flush = 0;
      end
    end else begin
      if_flush = id_bc || exception || (id_op_next == OP_FENCE_I);
    end
  end

  assign btb_if_pc = pc;
  always_comb begin : NEXT_PC
    if (exception || exception_reg) begin
      pc_next = mem_pc;
    end else if (id_op_next == OP_FENCE_I) begin
      pc_next = if_pc + 4;
    end else if (id_bc) begin
      if (~id_bp) begin
        if (id_op_next == OP_JALR) begin
          pc_next = id_rs1_fwd + id_imm_next;
        end else begin
          pc_next = if_pc + id_imm_next;
        end
      end else pc_next = if_pc + 4;
    end else begin
      pc_next = btb_pred_pc;
    end
  end

  always_ff @(posedge clk) begin : PC
    if (rst_p) begin
      pc <= 32'h7FFFFFFC;
      id_bp <= 0;
    end else begin
      if (if_flush) begin
        pc <= pc;  // Keep
      end else if (if_ready && (if_idle || im_ack_i)) begin
        pc <= pc_next;
        id_bp <= btb_pred_bc;
      end
    end
  end

  // =============
  // IF
  // =============

  always_comb begin : IF_MEM
    im_adr_o = (im_ack_i) ? pc_next : pc;  // Enable continuous fetch
    // im_adr_o = pc;
    im_dat_o = 0;
    im_we_o  = 0;
    if (!if_idle
        // && !im_ack_i
        ) begin
      im_sel_o = 4'b1111;
      im_stb_o = 1;
      im_cyc_o = 1;
    end else begin
      im_sel_o = 0;
      im_stb_o = 0;
      im_cyc_o = 0;
    end
  end

  always_ff @(posedge clk) begin : IF_REG
    if (rst_p) begin
      if_valid     <= 0;
      if_pc        <= 0;
      if_instr     <= 0;
      if_idle      <= 1;
      if_ec        <= EC_NONE;
      im_dat_i_reg <= 0;
    end else begin
      if (if_idle) begin

        if (if_flush) begin
          // Insert a bubble
          if_valid <= 0;
          im_dat_i_reg <= 0;
        end else if (if_ready) begin
          if (if_pc == 0) begin  // first cycle, pass it
            // Insert a bubble
            if_valid <= 0;
            if_instr <= 0;
            if_pc    <= pc; // To prevent deadlock
            if_idle  <= 0;  // Access memory
          end else begin
            if_valid <= 1;
            if_instr <= im_dat_i_reg;
            if_pc    <= pc;
            if_idle  <= 0; // Access memory
          end
        end
        // Else : Hold

      end else begin  // !if_idle


        if (im_ack_i) begin

          if (if_flush) begin
            // Insert a bubble
            if_valid     <= 0;
            im_dat_i_reg <= 0;
            // Then return to idle
            if_idle      <= 1;
          end else if (if_ready) begin
            // Update the regs
            if_valid <= 1;
            if_pc    <= pc;
            if_instr <= im_dat_i;
          end else begin
            // Hold the regs
            im_dat_i_reg <= im_dat_i;
            if_idle      <= 1;
          end

        end else begin  // !im_ack_i

          if (if_flush) begin
            // Insert a bubble
            if_valid     <= 0;
            im_dat_i_reg <= 0;
          end else if (if_ready) begin
            // Insert a bubble
            if_valid <= 0;
          end

        end
      end
    end
  end

  assign if_ready = id_ready;

  // =====================================
  // Instruction Decode
  // =====================================

  logic id_rd_ea;
  logic id_err_instr;
  exception_t id_ec_next;

  // ==================
  // Instruction decode & Signals
  // ==================
  always_comb begin : ID_OP
    id_op_next    = OP_NOP;
    id_rd_ea      = 0;
    id_rs1_ea     = 0;
    id_rs2_ea     = 0;
    id_ex_rs1_ea  = 0;
    id_ex_rs2_ea  = 0;
    id_mem_rs2_ea = 0;
    id_mem_load   = 0;
    id_mem_store  = 0;
    id_mem_csr    = 0;
    id_err_instr  = 0;
    case (if_instr[6:0])
      7'b0000000: begin
        // NOP
        if (if_instr == 32'd0) begin
          id_op_next = OP_NOP;
        end else begin
          id_op_next   = OP_NOP;
          id_err_instr = 1;
        end
      end
      7'b0110111: begin
        id_op_next = OP_LUI;
        id_rd_ea   = 1;
      end
      7'b0010111: begin
        id_op_next = OP_AUIPC;
        id_rd_ea   = 1;
      end
      7'b1101111: begin
        id_op_next = OP_JAL;
        id_rd_ea   = 1;
      end
      7'b1100111: begin
        case (if_instr[14:12])
          3'b000: begin
            id_op_next = OP_JALR;
            id_rd_ea   = 1;
            id_rs1_ea  = 1;
          end
          default: begin
            id_op_next   = OP_NOP;
            id_err_instr = 1;
          end
        endcase
      end
      7'b1100011: begin
        case (if_instr[14:12])
          3'b000: begin
            id_op_next = OP_BEQ;
            id_rs1_ea  = 1;
            id_rs2_ea  = 1;
          end
          3'b001: begin
            id_op_next = OP_BNE;
            id_rs1_ea  = 1;
            id_rs2_ea  = 1;
          end
          3'b100: begin
            id_op_next = OP_BLT;
            id_rs1_ea  = 1;
            id_rs2_ea  = 1;
          end
          3'b101: begin
            id_op_next = OP_BGE;
            id_rs1_ea  = 1;
            id_rs2_ea  = 1;
          end
          3'b110: begin
            id_op_next = OP_BLTU;
            id_rs1_ea  = 1;
            id_rs2_ea  = 1;
          end
          3'b111: begin
            id_op_next = OP_BGEU;
            id_rs1_ea  = 1;
            id_rs2_ea  = 1;
          end
          default: begin
            id_op_next   = OP_NOP;
            id_err_instr = 1;
          end
        endcase
      end
      7'b0000011: begin
        case (if_instr[14:12])
          3'b000: begin
            id_op_next   = OP_LB;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
            id_mem_load  = 1;
          end
          3'b001: begin
            id_op_next   = OP_LH;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
            id_mem_load  = 1;
          end
          3'b010: begin
            id_op_next   = OP_LW;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
            id_mem_load  = 1;
          end
          3'b100: begin
            id_op_next   = OP_LBU;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
            id_mem_load  = 1;
          end
          3'b101: begin
            id_op_next   = OP_LHU;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
            id_mem_load  = 1;
          end
          default: begin
            id_op_next   = OP_NOP;
            id_err_instr = 1;
          end
        endcase
      end
      7'b0100011: begin
        case (if_instr[14:12])
          3'b000: begin
            id_op_next    = OP_SB;
            id_ex_rs1_ea  = 1;
            id_mem_rs2_ea = 1;
            id_mem_store  = 1;
          end
          3'b001: begin
            id_op_next    = OP_SH;
            id_ex_rs1_ea  = 1;
            id_mem_rs2_ea = 1;
            id_mem_store  = 1;
          end
          3'b010: begin
            id_op_next    = OP_SW;
            id_ex_rs1_ea  = 1;
            id_mem_rs2_ea = 1;
            id_mem_store  = 1;
          end
          default: begin
            id_op_next   = OP_NOP;
            id_err_instr = 1;
          end
        endcase
      end
      7'b0010011: begin
        case (if_instr[14:12])
          3'b000: begin
            id_op_next   = OP_ADDI;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
          end
          3'b010: begin
            id_op_next   = OP_SLTI;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
          end
          3'b011: begin
            id_op_next   = OP_SLTIU;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
          end
          3'b100: begin
            id_op_next   = OP_XORI;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
          end
          3'b110: begin
            id_op_next   = OP_ORI;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
          end
          3'b111: begin
            id_op_next   = OP_ANDI;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
          end
          3'b001: begin
            if (if_instr[31:25] == 7'b0000000) begin
              id_op_next   = OP_SLLI;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
            end else if (if_instr[31:25] == 7'b0110000) begin
              if (if_instr[24:20] == 5'b00000) begin
                id_op_next = OP_CLZ;
                id_rd_ea = 1;
                id_ex_rs1_ea = 1;
              end else if (if_instr[24:20] == 5'b00010) begin
                id_op_next = OP_PCNT;
                id_rd_ea = 1;
                id_ex_rs1_ea = 1;
              end else begin
                id_op_next   = OP_NOP;
                id_err_instr = 1;
              end
            end else begin
              id_op_next   = OP_NOP;
              id_err_instr = 1;
            end
          end
          3'b101: begin
            if (if_instr[31:20] == 12'b011010000111) begin
              id_op_next   = OP_BREV8;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
            end else if (if_instr[31:25] == 7'b0000000) begin
              id_op_next   = OP_SRLI;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
            end else if (if_instr[31:25] == 7'b0100000) begin
              id_op_next   = OP_SRAI;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
            end else if (if_instr[31:27] == 5'b01101) begin
              id_op_next   = OP_GREVI;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
            end else begin
              id_op_next   = OP_NOP;
              id_err_instr = 1;
            end
          end
          default: begin
            id_op_next   = OP_NOP;
            id_err_instr = 1;
          end
        endcase
      end
      7'b0110011: begin
        case (if_instr[14:12])
          3'b000: begin
            if (if_instr[31:25] == 7'b0000000) begin
              id_op_next   = OP_ADD;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else if (if_instr[31:25] == 7'b0100000) begin
              id_op_next   = OP_SUB;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else begin
              id_op_next   = OP_NOP;
              id_err_instr = 1;
            end
          end
          3'b001: begin
            if (if_instr[31:25] == 7'b0000000) begin
              id_op_next   = OP_SLL;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else begin
              id_op_next   = OP_NOP;
              id_err_instr = 1;
            end
          end
          3'b010: begin
            if (if_instr[31:25] == 7'b0000000) begin
              id_op_next   = OP_SLT;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else begin
              id_op_next   = OP_NOP;
              id_err_instr = 1;
            end
          end
          3'b011: begin
            if (if_instr[31:25] == 7'b0000000) begin
              id_op_next   = OP_SLTU;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else begin
              id_op_next   = OP_NOP;
              id_err_instr = 1;
            end
          end
          3'b100: begin
            if (if_instr[31:25] == 7'b0000000) begin
              id_op_next   = OP_XOR;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else if (if_instr[31:25] == 7'b0000100) begin
              id_op_next   = OP_PACK;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else begin
              id_op_next   = OP_NOP;
              id_err_instr = 1;
            end
          end
          3'b101: begin
            if (if_instr[31:25] == 7'b0000000) begin
              id_op_next   = OP_SRL;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else if (if_instr[31:25] == 7'b0100000) begin
              id_op_next   = OP_SRA;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else begin
              id_op_next   = OP_NOP;
              id_err_instr = 1;
            end
          end
          3'b110: begin
            if (if_instr[31:25] == 7'b0000000) begin
              id_op_next   = OP_OR;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else begin
              id_op_next   = OP_NOP;
              id_err_instr = 1;
            end
          end
          3'b111: begin
            if (if_instr[31:25] == 7'b0000000) begin
              id_op_next   = OP_AND;
              id_rd_ea     = 1;
              id_ex_rs1_ea = 1;
              id_ex_rs2_ea = 1;
            end else begin
              id_op_next   = OP_NOP;
              id_err_instr = 1;
            end
          end
          default: begin
            id_op_next   = OP_NOP;
            id_err_instr = 1;
          end
        endcase
      end
      7'b0001111: begin
        case (if_instr[14:12])
          3'b000: begin
            id_op_next = OP_FENCE;  // DO NOTHING
          end
          3'b001: begin
            id_op_next = OP_FENCE_I;
          end
          default: begin
            id_op_next   = OP_NOP;
            id_err_instr = 1;
          end
        endcase
      end
      7'b1110011: begin
        case (if_instr[14:12])
          3'b000: begin
            case (if_instr[31:25])
              7'b0000000: begin
                if (if_instr[24:20] == 5'b00000) begin
                  id_op_next = OP_ECALL;
                end else if (if_instr[24:20] == 5'b00001) begin
                  id_op_next = OP_EBREAK;
                end else begin
                  id_op_next   = OP_NOP;
                  id_err_instr = 1;
                end
              end
              7'b0011000: begin
                if (if_instr[24:20] == 5'b00010) begin
                  id_op_next = OP_MRET;
                end else begin
                  id_op_next   = OP_NOP;
                  id_err_instr = 1;
                end
              end
              default: begin
                id_op_next   = OP_NOP;
                id_err_instr = 1;
              end
            endcase
          end
          3'b001: begin
            id_op_next   = OP_CSRRW;
            id_mem_csr   = 1;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
          end
          3'b010: begin
            id_op_next   = OP_CSRRS;
            id_mem_csr   = 1;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
          end
          3'b011: begin
            id_op_next   = OP_CSRRC;
            id_mem_csr   = 1;
            id_rd_ea     = 1;
            id_ex_rs1_ea = 1;
          end
          3'b101: begin
            id_op_next = OP_CSRRWI;
            id_mem_csr = 1;
            id_rd_ea   = 1;
          end
          3'b110: begin
            id_op_next = OP_CSRRSI;
            id_mem_csr = 1;
            id_rd_ea   = 1;
          end
          3'b111: begin
            id_op_next = OP_CSRRCI;
            id_mem_csr = 1;
            id_rd_ea   = 1;
          end
          default: begin
            id_op_next   = OP_NOP;
            id_err_instr = 1;
          end
        endcase
      end
      default: begin
        id_op_next   = OP_NOP;
        id_err_instr = 1;
      end
    endcase
  end


  // ==================
  // Immediate generation
  // ==================
  always_comb begin : ID_IMM_GEN
    id_imm_next = 0;
    if ((id_op_next == OP_LUI) || (id_op_next == OP_AUIPC)) begin
      id_imm_next = {if_instr[31:12], 12'b0};
    end else if (id_op_next == OP_JAL) begin
      id_imm_next = {
        {11{if_instr[31]}}, if_instr[31], if_instr[19:12], if_instr[20], if_instr[30:21], 1'b0
      };
    end else if (id_op_next == OP_JALR) begin
      id_imm_next = {{20{if_instr[31]}}, if_instr[31:21], 1'b0};
    end else if (
                      (id_op_next == OP_BEQ)
                   || (id_op_next == OP_BNE)
                   || (id_op_next == OP_BLT)
                   || (id_op_next == OP_BGE)
                   || (id_op_next == OP_BLTU)
                   || (id_op_next == OP_BGEU)
                ) begin
      id_imm_next = {
        {19{if_instr[31]}}, if_instr[31], if_instr[7], if_instr[30:25], if_instr[11:8], 1'b0
      };
    end else if (
                      (id_op_next == OP_LB)
                   || (id_op_next == OP_LH)
                   || (id_op_next == OP_LW)
                   || (id_op_next == OP_LBU)
                   || (id_op_next == OP_LHU)
                ) begin
      id_imm_next = {{20{if_instr[31]}}, if_instr[31:20]};
    end else if ((id_op_next == OP_SB) || (id_op_next == OP_SH) || (id_op_next == OP_SW)) begin
      id_imm_next = {{20{if_instr[31]}}, if_instr[31:25], if_instr[11:7]};
    end else if (
                      (id_op_next == OP_ADDI)
                   || (id_op_next == OP_SLTI)
                   || (id_op_next == OP_SLTIU)
                   || (id_op_next == OP_XORI)
                   || (id_op_next == OP_ORI)
                   || (id_op_next == OP_ANDI)
                   || (id_op_next == OP_SLLI)
                   || (id_op_next == OP_SRLI)
                   || (id_op_next == OP_SRAI)
                ) begin
      id_imm_next = {{20{if_instr[31]}}, if_instr[31:20]};
    end else
    if (
         (id_op_next == OP_CSRRWI)
      || (id_op_next == OP_CSRRSI)
      || (id_op_next == OP_CSRRCI)
    ) begin
      id_imm_next = {27'd0, if_instr[19:15]};
    end else if (id_op_next == OP_GREVI) begin
      id_imm_next = {27'd0, if_instr[24:20]};
    end else begin
      id_imm_next = 0;
    end
  end



  // ==================
  // Branch condition
  // ==================
  always_comb begin : ID_BC
    id_bc = 0;
    if (!data_hazard) begin
      case (id_op_next)
        OP_BEQ: begin
          id_bc = (id_rs1_fwd == id_rs2_fwd);
        end
        OP_BNE: begin
          id_bc = (id_rs1_fwd != id_rs2_fwd);
        end
        OP_BLT: begin
          id_bc = ($signed(id_rs1_fwd) < $signed(id_rs2_fwd));
        end
        OP_BGE: begin
          id_bc = ($signed(id_rs1_fwd) >= $signed(id_rs2_fwd));
        end
        OP_BLTU: begin
          id_bc = (id_rs1_fwd < id_rs2_fwd);
        end
        OP_BGEU: begin
          id_bc = (id_rs1_fwd >= id_rs2_fwd);
        end
        OP_JAL: begin
          id_bc = 1;
        end
        OP_JALR: begin
          id_bc = 1;
        end
        default: begin
          id_bc = 0;
        end
      endcase
      id_bc = id_bc ^ id_bp;
    end
  end


  // ===============
  // Exception
  // ===============
  always_comb begin : ID_EC_NEXT
    id_ec_next = EC_NONE;
    if (if_ec[5]) begin
      id_ec_next = if_ec;
    end else if (id_err_instr) begin
      id_ec_next = EC_ILLEGAL_INSTRUCTION;
    end else if (id_op_next == OP_ECALL) begin
      if (privilege == PRIVILEGE_U) begin
        id_ec_next = EC_ECALL_FROM_U;
      end else if (privilege == PRIVILEGE_S) begin
        id_ec_next = EC_ECALL_FROM_S;
      end else if (privilege == PRIVILEGE_M) begin
        id_ec_next = EC_ECALL_FROM_M;
      end
    end else if (id_op_next == OP_EBREAK) begin
      id_ec_next = EC_BREAKPOINT;
    end else begin
      id_ec_next = EC_NONE;
    end
  end


  always_comb begin : BTB_WE
    btb_id_we = 0;
    case (id_op_next)
      OP_BEQ: begin
        btb_id_we = 1;
      end
      OP_BNE: begin
        btb_id_we = 1;
      end
      OP_BLT: begin
        btb_id_we = 1;
      end
      OP_BGE: begin
        btb_id_we = 1;
      end
      OP_BLTU: begin
        btb_id_we = 1;
      end
      OP_BGEU: begin
        btb_id_we = 1;
      end
      OP_JAL: begin
        btb_id_we = 1;
      end
      default: begin
        btb_id_we = 0;
      end
    endcase
  end

  // Branch Prediction
  assign btb_id_pc = if_pc;
  assign btb_id_offset = id_imm_next;
  assign btb_id_bc = id_bc;

  // Register File Read
  assign rf_raddr_a = if_instr[19:15];  // rs1
  assign rf_raddr_b = if_instr[24:20];  // rs2

  // CSR decode
  assign id_csr_next = if_instr[31:20];


  // ==================
  // ID
  // ==================
  always_ff @(posedge clk) begin : ID_REG
    if (rst_p) begin
      id_pc         <= 0;
      id_op         <= 0;
      id_imm        <= 0;
      id_rd         <= 0;
      id_valid      <= 0;
      id_rs1_dat    <= 0;
      id_rs2_dat    <= 0;
      id_rs1        <= 0;
      id_rs2        <= 0;
      id_csr        <= 0;
      id_ec         <= EC_NONE;
      ex_rs1_ea     <= 0;
      ex_rs2_ea     <= 0;
      ex_mem_rs2_ea <= 0;
      ex_mem_load   <= 0;
      ex_mem_store  <= 0;
      ex_mem_csr    <= 0;
    end else if (id_flush) begin
      id_pc         <= 0;
      id_op         <= 0;
      id_imm        <= 0;
      id_rd         <= 0;
      id_valid      <= 0;
      id_rs1_dat    <= 0;
      id_rs2_dat    <= 0;
      id_rs1        <= 0;
      id_rs2        <= 0;
      id_csr        <= 0;
      id_ec         <= EC_NONE;
      ex_rs1_ea     <= 0;
      ex_rs2_ea     <= 0;
      ex_mem_rs2_ea <= 0;
      ex_mem_load   <= 0;
      ex_mem_store  <= 0;
      ex_mem_csr    <= 0;
    end else if (id_ready) begin
      if (if_flush) begin
        id_pc         <= 0;
        id_op         <= 0;
        id_imm        <= 0;
        id_rd         <= 0;
        id_valid      <= 0;
        id_rs1_dat    <= 0;
        id_rs2_dat    <= 0;
        id_rs1        <= 0;
        id_rs2        <= 0;
        id_csr        <= 0;
        id_ec         <= EC_NONE;
        ex_rs1_ea     <= 0;
        ex_rs2_ea     <= 0;
        ex_mem_rs2_ea <= 0;
        ex_mem_load   <= 0;
        ex_mem_store  <= 0;
        ex_mem_csr    <= 0;
      end else if ((if_valid && (!id_bc))  // Normal Case
          || (!if_flush && id_bc && if_idle)  // Special Case for JALR t0, t0
          ) begin  // Not a bubble
        id_pc         <= if_pc;
        id_op         <= id_op_next;
        id_imm        <= id_imm_next;
        id_rd         <= (id_rd_ea) ? if_instr[11:7] : 0;  // rd
        id_rs1_dat    <= id_rs1_fwd;
        id_rs2_dat    <= id_rs2_fwd;
        id_rs1        <= rf_raddr_a;
        id_rs2        <= rf_raddr_b;
        id_csr        <= id_csr_next;
        id_ec         <= id_ec_next;
        id_valid      <= 1;
        ex_rs1_ea     <= id_ex_rs1_ea;
        ex_rs2_ea     <= id_ex_rs2_ea;
        ex_mem_rs2_ea <= id_mem_rs2_ea;
        ex_mem_load   <= id_mem_load;
        ex_mem_store  <= id_mem_store;
        ex_mem_csr    <= id_mem_csr;
      end else begin
        id_pc         <= 0;
        id_op         <= 0;
        id_imm        <= 0;
        id_rd         <= 0;
        id_valid      <= 0;
        id_rs1_dat    <= 0;
        id_rs2_dat    <= 0;
        id_rs1        <= 0;
        id_rs2        <= 0;
        id_csr        <= 0;
        id_ec         <= EC_NONE;
        ex_rs1_ea     <= 0;
        ex_rs2_ea     <= 0;
        ex_mem_rs2_ea <= 0;
        ex_mem_load   <= 0;
        ex_mem_store  <= 0;
        ex_mem_csr    <= 0;
      end
    end else if ((id_rs1_data_hazard || id_rs2_data_hazard) && ex_ready) begin
      // NOTE: When EXE is stalled, bubble should not be inserted
      // Insert a bubble
      id_pc         <= 0;
      id_op         <= 0;
      id_imm        <= 0;
      id_rd         <= 0;
      id_valid      <= 0;
      id_rs1_dat    <= 0;
      id_rs2_dat    <= 0;
      id_rs1        <= 0;
      id_rs2        <= 0;
      id_csr        <= 0;
      id_ec         <= EC_NONE;
      ex_rs1_ea     <= 0;
      ex_rs2_ea     <= 0;
      ex_mem_rs2_ea <= 0;
      ex_mem_load   <= 0;
      ex_mem_store  <= 0;
      ex_mem_csr    <= 0;
    end
  end

  assign id_ready = (!id_rs1_data_hazard) && (!id_rs2_data_hazard) && (ex_ready || !id_valid);
  assign id_flush = exception;

  // =====================================
  // Execute
  // =====================================


  always_comb begin : EX_ALU
    case (id_op)
      // J type
      OP_JAL: begin
        alu_a  = id_pc;
        alu_b  = 4;
        alu_op = ALU_ADD;
      end
      // I type
      OP_JALR: begin
        alu_a  = id_pc;
        alu_b  = 4;
        alu_op = ALU_ADD;
      end
      // U type
      OP_LUI: begin
        alu_a  = 0;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      OP_AUIPC: begin
        alu_a  = id_pc;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      // I type
      OP_LB: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      OP_LH: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      OP_LW: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      OP_LBU: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      OP_LHU: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      // S type
      OP_SB: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      OP_SH: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      OP_SW: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      // I type
      OP_ADDI: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_ADD;
      end
      OP_SLTI: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_SLT;
      end
      OP_SLTIU: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_SLTU;
      end
      OP_XORI: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_XOR;
      end
      OP_ORI: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_OR;
      end
      OP_ANDI: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm;
        alu_op = ALU_AND;
      end
      OP_SLLI: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm[4:0];
        alu_op = ALU_SLL;
      end
      OP_SRLI: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm[4:0];
        alu_op = ALU_SRL;
      end
      OP_SRAI: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm[4:0];
        alu_op = ALU_SRA;
      end
      OP_GREVI: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = id_imm[4:0];
        alu_op = ALU_GRV;
      end
      OP_BREV8: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = 0;
        alu_op = ALU_BREV8;
      end
      // R type
      OP_ADD: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = ex_rs2_fwd;
        alu_op = ALU_ADD;
      end
      OP_SUB: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = ex_rs2_fwd;
        alu_op = ALU_SUB;
      end
      OP_SLL: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = ex_rs2_fwd;
        alu_op = ALU_SLL;
      end
      OP_SLT: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = ex_rs2_fwd;
        alu_op = ALU_SLT;
      end
      OP_SLTU: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = ex_rs2_fwd;
        alu_op = ALU_SLTU;
      end
      OP_XOR: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = ex_rs2_fwd;
        alu_op = ALU_XOR;
      end
      OP_SRL: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = ex_rs2_fwd;
        alu_op = ALU_SRL;
      end
      OP_SRA: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = ex_rs2_fwd;
        alu_op = ALU_SRA;
      end
      OP_OR: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = ex_rs2_fwd;
        alu_op = ALU_OR;
      end
      OP_AND: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = ex_rs2_fwd;
        alu_op = ALU_AND;
      end
      // CSR instructions, simply pass rs1 or imm
      OP_CSRRW: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = 0;
        alu_op = ALU_ADD;
      end
      OP_CSRRS: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = 0;
        alu_op = ALU_ADD;
      end
      OP_CSRRC: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = 0;
        alu_op = ALU_ADD;
      end
      OP_CSRRWI: begin
        alu_a  = id_imm;
        alu_b  = 0;
        alu_op = ALU_ADD;
      end
      OP_CSRRSI: begin
        alu_a  = id_imm;
        alu_b  = 0;
        alu_op = ALU_ADD;
      end
      OP_CSRRCI: begin
        alu_a  = id_imm;
        alu_b  = 0;
        alu_op = ALU_ADD;
      end
      // Bit manipulation
      OP_CLZ: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = 0;
        alu_op = ALU_CLZ;
      end
      OP_PCNT: begin
        alu_a  = ex_rs1_fwd;
        alu_b  = 0;
        alu_op = ALU_PCNT;
      end
      OP_PACK: begin
        alu_a  = {ex_rs2_fwd[15:0], ex_rs1_fwd[15:0]};
        alu_b  = 0;
        alu_op = ALU_ADD;
      end
      default: begin
        alu_a  = 0;
        alu_b  = 0;
        alu_op = ALU_NOP;
      end
    endcase
  end


  assign ex_forward_valid = (
        ex_valid
        && (
             (ex_op == OP_JAL)
          || (ex_op == OP_JALR)
          || (ex_op == OP_LUI)
          || (ex_op == OP_AUIPC)
          || (ex_op == OP_ADDI)
          || (ex_op == OP_SLTI)
          || (ex_op == OP_SLTIU)
          || (ex_op == OP_XORI)
          || (ex_op == OP_ORI)
          || (ex_op == OP_ANDI)
          || (ex_op == OP_SLLI)
          || (ex_op == OP_SRLI)
          || (ex_op == OP_SRAI)
          || (ex_op == OP_ADD)
          || (ex_op == OP_SUB)
          || (ex_op == OP_SLL)
          || (ex_op == OP_SLT)
          || (ex_op == OP_SLTU)
          || (ex_op == OP_XOR)
          || (ex_op == OP_SRL)
          || (ex_op == OP_SRA)
          || (ex_op == OP_OR)
          || (ex_op == OP_AND)
          || (ex_op == OP_GREVI)
          || (ex_op == OP_BREV8)
        )
    );


  always_ff @(posedge clk) begin : EX_REG
    if (rst_p) begin
      ex_pc         <= 0;
      ex_op         <= 0;
      ex_rd         <= 0;
      ex_imm        <= 0;
      ex_rs2_dat    <= 0;
      ex_rs2        <= 0;
      ex_csr        <= 0;
      ex_valid      <= 0;
      ex_ec         <= EC_NONE;
      mem_rs2_ea    <= 0;
      mem_mem_load  <= 0;
      mem_mem_store <= 0;
      mem_mem_csr   <= 0;
    end else if (ex_flush) begin
      ex_pc         <= 0;
      ex_op         <= 0;
      ex_rd         <= 0;
      ex_imm        <= 0;
      ex_rs2_dat    <= 0;
      ex_rs2        <= 0;
      ex_csr        <= 0;
      ex_valid      <= 0;
      ex_ec         <= EC_NONE;
      mem_rs2_ea    <= 0;
      mem_mem_load  <= 0;
      mem_mem_store <= 0;
      mem_mem_csr   <= 0;
    end else if (ex_ready) begin
      ex_pc         <= id_pc;
      ex_op         <= id_op;
      ex_rd         <= id_rd;
      ex_imm        <= alu_y;
      ex_rs2_dat    <= ex_rs2_fwd;
      ex_rs2        <= id_rs2;
      ex_csr        <= id_csr;
      ex_valid      <= id_valid;
      ex_ec         <= id_ec;
      mem_rs2_ea    <= ex_mem_rs2_ea;
      mem_mem_load  <= ex_mem_load;
      mem_mem_store <= ex_mem_store;
      mem_mem_csr   <= ex_mem_csr;
    end else if ((ex_rs1_data_hazard || ex_rs2_data_hazard) && mem_ready) begin
      // NOTE: When MEM is stalled, bubble should not be inserted
      // Insert a bubble
      ex_pc         <= 0;
      ex_op         <= 0;
      ex_rd         <= 0;
      ex_imm        <= 0;
      ex_rs2_dat    <= 0;
      ex_rs2        <= 0;
      ex_csr        <= 0;
      ex_valid      <= 0;
      ex_ec         <= EC_NONE;
      mem_rs2_ea    <= 0;
      mem_mem_load  <= 0;
      mem_mem_store <= 0;
      mem_mem_csr   <= 0;
    end
  end

  assign ex_ready = (!ex_rs1_data_hazard) && (!ex_rs2_data_hazard) && (mem_ready || !ex_valid);
  assign ex_flush = exception;

  // =====================================
  // MEM Stage
  // =====================================
  logic [ 3:0] mem_sel;
  logic [31:0] mem_data_o;

  logic [ 3:0] mem_sel_next;  // Combinational
  logic [31:0] mem_data_o_next;  // Combinational

  logic [31:0] mem_data_i;  // Combinational

  logic [31:0] mem_mie;
  logic [31:0] mem_mip;
  logic [31:0] mem_mstatus;
  logic [31:0] mem_mepc;
  logic [31:0] mem_mtvec;
  logic [31:0] mem_mtval;
  logic [31:0] mem_mcause;

  typedef enum logic [4:0] {
    MEM_IDLE,
    MEM_MEM,

    MEM_MTIME,
    MEM_MTIMECMP,

    MEM_CSR_READ,
    MEM_CSR_WRITE,

    MEM_HANDLE_EC,  // state for processing exception

    MEM_RD_MIE,      // state for reading MIE
    MEM_RD_MIP,      // state for reading MIP
    MEM_RD_MSTATUS,  // state for reading MSTATUS
    MEM_RD_MEPC,     // state for reading MEPC
    MEM_RD_MTVEC,    // state for reading MTVEC

    MEM_CHECK_CSR,  // state for checking CSR

    MEM_WT_MEPC,   // state for writing MEPC
    MEM_WT_MTVAL,  // state for writing MTVAL
    MEM_WT_MCAUSE, // state for writing MCAUSE

    // mret only need to write MSTATUS, MIP(reset)
    MEM_WT_MIP,     // state for writing MIP
    MEM_WT_MSTATUS,  // state for writing MSTATUS

    MEM_EC_DONE  // state for finishing exception handling
  } mem_state_t;
  mem_state_t mem_state, mem_state_next;


  // ==================
  // Memory Access
  // ==================
  always_comb begin : MEM_ACCESS
    dm_adr_o = 0;
    dm_dat_o = 0;
    dm_we_o  = 0;
    dm_sel_o = 0;
    dm_stb_o = 0;
    dm_cyc_o = 0;
    if (mem_state == MEM_MEM) begin
      if ((mem_op == OP_LB)  // load
          ||(mem_op == OP_LH)
          ||(mem_op == OP_LW)
          ||(mem_op == OP_LBU)
          ||(mem_op == OP_LHU)
      ) begin
        dm_adr_o = mem_imm;
        dm_dat_o = 0;
        dm_we_o  = 0;
        dm_sel_o = mem_sel;
        dm_stb_o = 1;
        dm_cyc_o = 1;
      end else if ((mem_op == OP_SB)  // store
          || (mem_op == OP_SH) || (mem_op == OP_SW)) begin
        dm_adr_o = mem_imm;
        dm_dat_o = mem_data_o;
        dm_we_o  = 1;
        dm_sel_o = mem_sel;
        dm_stb_o = 1;
        dm_cyc_o = 1;
      end
    end
  end

  always_comb begin : MEM_DATA_I
    mem_data_i = 0;
    if ((mem_op == OP_LB) || (mem_op == OP_LH) || (mem_op == OP_LW)) begin
      // Sign extension
      case (mem_sel)
        4'b0001: mem_data_i = {{24{dm_dat_i[7]}}, dm_dat_i[7:0]};
        4'b0010: mem_data_i = {{24{dm_dat_i[15]}}, dm_dat_i[15:8]};
        4'b0100: mem_data_i = {{24{dm_dat_i[23]}}, dm_dat_i[23:16]};
        4'b1000: mem_data_i = {{24{dm_dat_i[31]}}, dm_dat_i[31:24]};
        4'b0011: mem_data_i = {{16{dm_dat_i[15]}}, dm_dat_i[15:0]};
        4'b1100: mem_data_i = {{16{dm_dat_i[31]}}, dm_dat_i[31:16]};
        default: mem_data_i = dm_dat_i;
      endcase
    end else if ((mem_op == OP_LBU) || (mem_op == OP_LHU)) begin
      // Zero extension
      case (mem_sel)
        4'b0001: mem_data_i = {24'd0, dm_dat_i[7:0]};
        4'b0010: mem_data_i = {24'd0, dm_dat_i[15:8]};
        4'b0100: mem_data_i = {24'd0, dm_dat_i[23:16]};
        4'b1000: mem_data_i = {24'd0, dm_dat_i[31:24]};
        4'b0011: mem_data_i = {16'd0, dm_dat_i[15:0]};
        4'b1100: mem_data_i = {16'd0, dm_dat_i[31:16]};
        default: mem_data_i = dm_dat_i;
      endcase
    end
  end


  always_comb begin : MEM_DATA_O
    mem_sel_next    = 4'b1111;
    mem_data_o_next = mem_rs2_fwd;
    // Byte selection and Output data
    if ((ex_op == OP_LB) || (ex_op == OP_LBU) || (ex_op == OP_SB)) begin
      case (ex_imm[1:0])
        2'd0: begin
          mem_sel_next    = 4'b0001;
          mem_data_o_next = {24'd0, mem_rs2_fwd[7:0]};
        end
        2'd1: begin
          mem_sel_next    = 4'b0010;
          mem_data_o_next = {16'd0, mem_rs2_fwd[7:0], 8'd0};
        end
        2'd2: begin
          mem_sel_next    = 4'b0100;
          mem_data_o_next = {8'd0, mem_rs2_fwd[7:0], 16'd0};
        end
        2'd3: begin
          mem_sel_next    = 4'b1000;
          mem_data_o_next = {mem_rs2_fwd[7:0], 24'd0};
        end
        default: begin
          mem_sel_next    = 0;
          mem_data_o_next = 0;
        end
      endcase
    end else if ((ex_op == OP_LH) || (ex_op == OP_LHU) || (ex_op == OP_SH)) begin
      case (ex_imm[1:0])
        2'd0: begin
          mem_sel_next    = 4'b0011;
          mem_data_o_next = {16'd0, mem_rs2_fwd[15:0]};
        end
        2'd2: begin
          mem_sel_next    = 4'b1100;
          mem_data_o_next = {mem_rs2_fwd[15:0], 16'd0};
        end
        default: begin
          mem_sel_next    = 0;
          mem_data_o_next = 0;
        end
      endcase
    end

  end


  // ==================
  // CSR Access
  // ==================
  always_comb begin : MEM_CSR_SIGNALS
    csr_addr_o = CSR_MIE;
    csr_data_o = 0;
    csr_we_o   = 0;
    case (mem_state)
      MEM_CSR_READ: begin
        csr_addr_o = mem_csr;
      end
      MEM_CSR_WRITE: begin
        csr_addr_o = mem_csr;
        if ((mem_op == OP_CSRRW) || (mem_op == OP_CSRRWI)) begin
          csr_data_o = mem_data_o;
          csr_we_o   = 1;
        end else if ((mem_op == OP_CSRRS) || (mem_op == OP_CSRRSI)) begin
          csr_data_o = mem_imm | mem_data_o;
          csr_we_o   = 1;
        end else if ((mem_op == OP_CSRRC) || (mem_op == OP_CSRRCI)) begin
          csr_data_o = mem_imm & (~mem_data_o);  // mem_imm is csr, mem_data_o is rs1/imm
          csr_we_o   = 1;
        end else begin
          csr_data_o = 0;
          csr_we_o   = 0;
        end
      end
      MEM_RD_MIE: begin
        csr_addr_o = CSR_MIE;
        csr_we_o   = 0;
      end
      MEM_RD_MIP: begin
        csr_addr_o = CSR_MIP;
        csr_we_o   = 0;
      end
      MEM_RD_MSTATUS: begin
        csr_addr_o = CSR_MSTATUS;
        csr_we_o   = 0;
      end
      MEM_RD_MEPC: begin
        csr_addr_o = CSR_MEPC;
        csr_we_o   = 0;
      end
      MEM_RD_MTVEC: begin
        csr_addr_o = CSR_MTVEC;
        csr_we_o   = 0;
      end
      MEM_WT_MEPC: begin
        csr_addr_o = CSR_MEPC;
        csr_data_o = mem_mepc;
        csr_we_o   = 1;
      end
      MEM_WT_MTVAL: begin
        csr_addr_o = CSR_MTVAL;
        csr_data_o = mem_mtval;
        csr_we_o   = 1;
      end
      MEM_WT_MCAUSE: begin
        csr_addr_o = CSR_MCAUSE;
        csr_data_o = mem_mcause;
        csr_we_o   = 1;
      end
      MEM_WT_MIP: begin
        csr_addr_o = CSR_MIP;
        csr_data_o = mem_mip;
        csr_we_o   = 1;
      end
      MEM_WT_MSTATUS: begin
        csr_addr_o = CSR_MSTATUS;
        csr_data_o = mem_mstatus;
        csr_we_o   = 1;
      end
      default: begin
        csr_addr_o = CSR_MIE;  // Read MIE by default
        csr_data_o = 0;
        csr_we_o   = 0;
      end
    endcase
  end


  // ==================
  // State Transition
  // ==================
  always_comb begin : MEM_STATE_NEXT
    mem_state_next = MEM_IDLE;
    case (mem_state)
      MEM_IDLE: begin
        mem_state_next = MEM_IDLE;
        if (mem_ready && ex_valid) begin
          if ((ex_ec != EC_NONE) || (ex_op == OP_MRET) || (
            (mtime >= mtimecmp) && csr_data_i[MIE_MTIE] && (privilege == PRIVILEGE_U) // timeout
              )) begin
            mem_state_next = MEM_HANDLE_EC;
          end else if (mem_mem_load || mem_mem_store) begin
            // Special case for timer access
            if ((ex_imm == MTIME_LADDR) || (ex_imm == MTIME_HADDR)) begin
              mem_state_next = MEM_MTIME;
            end else if ((ex_imm == MTIMECMP_LADDR) || (ex_imm == MTIMECMP_HADDR)) begin
              mem_state_next = MEM_MTIMECMP;
            end else begin
              mem_state_next = MEM_MEM;
            end
          end else if (mem_mem_csr) begin
            mem_state_next = MEM_CSR_READ;
          end else begin
            mem_state_next = MEM_IDLE;
          end
        end
      end
      MEM_MEM: begin
        if (dm_ack_i) begin
          mem_state_next = MEM_IDLE;
        end else begin
          mem_state_next = MEM_MEM;
        end
      end
      MEM_MTIME: begin
        mem_state_next = MEM_IDLE;
      end
      MEM_MTIMECMP: begin
        mem_state_next = MEM_IDLE;
      end
      MEM_CSR_READ: begin
        mem_state_next = MEM_CSR_WRITE;
      end
      MEM_CSR_WRITE: begin
        if (csr_error_i) begin
          mem_state_next = MEM_HANDLE_EC;
        end else begin
          mem_state_next = MEM_IDLE;
        end
      end
      MEM_HANDLE_EC: begin
        mem_state_next = MEM_RD_MIE;
      end
      MEM_RD_MIE: begin
        mem_state_next = MEM_RD_MIP;
      end
      MEM_RD_MIP: begin
        mem_state_next = MEM_RD_MSTATUS;
      end
      MEM_RD_MSTATUS: begin
        mem_state_next = MEM_RD_MEPC;
      end
      MEM_RD_MEPC: begin
        mem_state_next = MEM_RD_MTVEC;
      end
      MEM_RD_MTVEC: begin
        mem_state_next = MEM_CHECK_CSR;
      end
      MEM_CHECK_CSR: begin
        mem_state_next = MEM_IDLE;
        if (privilege == PRIVILEGE_M) begin
          if (mem_ec[5]) begin
            // Check whether M -> M is enabled
            if (mem_mstatus[MSTATUS_MIE]) begin
              mem_state_next = MEM_WT_MEPC;
            end
          end else if (mem_op == OP_MRET) begin
            // mret from M, Always enable
            mem_state_next = MEM_WT_MIP;
          end
        end else if (privilege == PRIVILEGE_U) begin
          if (mem_op != OP_MRET) begin
            // U->M, Always enable
            mem_state_next = MEM_WT_MEPC;
          end
        end
      end
      MEM_WT_MEPC: begin
        mem_state_next = MEM_WT_MTVAL;
      end
      MEM_WT_MTVAL: begin
        mem_state_next = MEM_WT_MCAUSE;
      end
      MEM_WT_MCAUSE: begin
        mem_state_next = MEM_WT_MIP;
      end
      MEM_WT_MIP: begin
        mem_state_next = MEM_WT_MSTATUS;
      end
      MEM_WT_MSTATUS: begin
        mem_state_next = MEM_EC_DONE;
      end
      MEM_EC_DONE: begin
        if (if_idle && (cpu_fence_state == CPU_FENCE_IDLE)) begin
          mem_state_next = MEM_IDLE;
        end else begin
          mem_state_next = MEM_EC_DONE;
        end
      end
      default: begin
        mem_state_next = MEM_IDLE;
      end
    endcase
  end


  always_ff @(posedge clk) begin : MEM_STATE
    if (rst_p) begin
      mem_state <= MEM_IDLE;
    end else begin
      mem_state <= mem_state_next;
    end
  end


  always_ff @(posedge clk) begin : MEM_REG
    if (rst_p) begin

      mem_pc      <= 0;
      mem_op      <= 0;
      mem_rd      <= 0;
      mem_imm     <= 0;
      mem_csr     <= 0;
      mem_valid   <= 0;
      mem_sel     <= 0;
      mem_data_o  <= 0;
      mem_ec      <= EC_NONE;
      privilege   <= PRIVILEGE_M;

      mem_mie     <= 0;
      mem_mip     <= 0;
      mem_mstatus <= 0;
      mem_mepc    <= 0;
      mem_mtvec   <= 0;
      mem_mtval   <= 0;
      mem_mcause  <= 0;

    end else begin
      case (mem_state)
        MEM_IDLE: begin
          if (mem_ready) begin
            mem_pc  <= ex_pc;
            mem_op  <= ex_op;
            mem_rd  <= ex_rd;
            mem_imm <= ex_imm;
            mem_csr <= ex_csr;
            mem_ec  <= ex_ec;
            if (
                  (mem_state_next == MEM_MEM)
                ||(mem_state_next == MEM_MTIME)
                ||(mem_state_next == MEM_MTIMECMP)
              ) begin  // Need to access memory / timer
              mem_valid <= 0;
              // Byte selection and Output data
              mem_sel    <= mem_sel_next;
              mem_data_o <= mem_data_o_next;
            end else if (mem_state_next == MEM_CSR_READ) begin
              mem_valid <= 0;
            end else if (mem_state_next == MEM_HANDLE_EC) begin
              mem_valid <= 0;
            end else begin
              // No memory access
              mem_valid <= ex_valid;
              mem_sel   <= 0;
            end
          end else if (mem_data_hazard) begin
            // Insert a bubble
            mem_pc     <= 0;
            mem_op     <= 0;
            mem_rd     <= 0;
            mem_csr    <= 0;
            mem_imm    <= 0;
            mem_valid  <= 0;
            mem_sel    <= 0;
            mem_data_o <= 0;
          end
        end
        MEM_MTIME: begin
          if ((mem_op == OP_LW) && (mem_imm == MTIME_LADDR)) begin
            mem_imm <= mtime[31:0];
          end else if ((mem_op == OP_LW) && (mem_imm == MTIME_HADDR)) begin
            mem_imm <= mtime[63:32];
          end
          mem_valid <= 1;
        end
        MEM_MTIMECMP: begin
          if ((mem_op == OP_LW) && (mem_imm == MTIMECMP_LADDR)) begin
            mem_imm <= mtimecmp[31:0];
          end else if ((mem_op == OP_LW) && (mem_imm == MTIMECMP_HADDR)) begin
            mem_imm <= mtimecmp[63:32];
          end
          mem_valid <= 1;
        end
        MEM_MEM: begin
          if (dm_ack_i) begin
            mem_imm   <= mem_data_i;
            mem_valid <= 1;
          end
        end
        MEM_CSR_READ: begin
          mem_data_o <= mem_imm;
          mem_imm    <= csr_data_i;
          mem_valid <= 0;
        end
        MEM_CSR_WRITE: begin
          mem_ec <= (csr_error_i) ? EC_ILLEGAL_INSTRUCTION : EC_NONE;
          mem_valid <= 1;
        end
        MEM_HANDLE_EC: begin
          if ((!mem_ec[5]) && (mtime >= mtimecmp)) begin
            // timeout
            mem_ec <= EC_M_TIMER;
          end
        end
        MEM_RD_MIE: begin
          mem_mie <= csr_data_i;
        end
        MEM_RD_MIP: begin
          mem_mip <= csr_data_i;
        end
        MEM_RD_MSTATUS: begin
          mem_mstatus <= csr_data_i;
        end
        MEM_RD_MEPC: begin
          mem_mepc <= csr_data_i;
        end
        MEM_RD_MTVEC: begin
          mem_mtvec <= csr_data_i;
        end
        MEM_CHECK_CSR: begin
          if (privilege == PRIVILEGE_M) begin
            if (mem_ec[5]) begin
              // Check whether M -> M is enabled
              if (mem_mstatus[MSTATUS_MIE]) begin
                mem_mepc                                 <= mem_pc;
                mem_mcause                               <= {mem_ec[4], 27'd0, mem_ec[3:0]};
                mem_mstatus[MSTATUS_MPP_H:MSTATUS_MPP_L] <= PRIVILEGE_M;
                mem_pc                                   <= mem_mtvec;  // BASE mode only
                // Disable nested interrupt
                mem_mstatus[MSTATUS_MIE]                 <= 0;
                mem_mstatus[MSTATUS_MPIE]                <= mem_mstatus[MSTATUS_MIE];
              end
            end else if (mem_op == OP_MRET) begin
              // mret from M, Always enable
              case (mem_mstatus[MSTATUS_MPP_H:MSTATUS_MPP_L])
                PRIVILEGE_U: begin
                  privilege <= PRIVILEGE_U;
                end
                PRIVILEGE_M: begin
                  privilege <= PRIVILEGE_M;
                end
                default: begin
                  privilege <= PRIVILEGE_M;
                end
              endcase
              mem_mstatus[MSTATUS_MIE]                 <= mem_mstatus[MSTATUS_MPIE];
              mem_mstatus[MSTATUS_MPP_H:MSTATUS_MPP_L] <= PRIVILEGE_M;
              mem_pc                                   <= mem_mepc;
              // Reset MTIP
              if (mtime < mtimecmp) begin
                mem_mip[MIP_MTIP] <= 0;
              end
            end
          end else if (privilege == PRIVILEGE_U) begin
            if (mem_ec[5]) begin
              // U->M, Always enable
              case (mem_mstatus[MSTATUS_MPP_H:MSTATUS_MPP_L])
                PRIVILEGE_U: begin
                  privilege <= PRIVILEGE_U;
                end
                PRIVILEGE_M: begin
                  privilege <= PRIVILEGE_M;
                end
                default: begin
                  privilege <= PRIVILEGE_M;
                end
              endcase
              mem_mepc                                 <= mem_pc;
              mem_mcause                               <= {mem_ec[4], 27'd0, mem_ec[3:0]};
              mem_mstatus[MSTATUS_MPP_H:MSTATUS_MPP_L] <= PRIVILEGE_U;
              mem_pc                                   <= mem_mtvec;  // BASE mode only
              // Disable nested interrupt
              mem_mstatus[MSTATUS_MIE]                 <= 0;
              mem_mstatus[MSTATUS_MPIE]                <= mem_mstatus[MSTATUS_MIE];
              // Set MTIP
              if (mem_ec == EC_M_TIMER) begin
                mem_mip[MIP_MTIP] <= 1;
              end
            end
          end
        end
        MEM_EC_DONE: begin
          mem_valid <= 0;
          mem_op    <= 0;
          mem_rd    <= 0;
        end
        default: begin
          // Do nothing
        end
      endcase
    end
  end


  assign mem_idle = (mem_state == MEM_IDLE);
  assign mem_forward_valid = mem_valid && mem_idle;
  assign mem_ready = mem_idle && (!mem_data_hazard) && (wb_ready || (!mem_valid));
  assign exception = (mem_state == MEM_EC_DONE);

  always_ff @(posedge clk) begin : EXCEPTION_REG
    if (rst_p) begin
      exception_reg <= 0;
    end else begin
      exception_reg <= exception;
    end
  end

  // =====================================
  // Write Back
  // =====================================

  always_comb begin : WB_RF
    rf_we_p  = mem_valid && (mem_rd != 0);
    rf_waddr = mem_rd;
    rf_wdata = mem_imm;
  end

  assign wb_ready = 1;

  // =====================================
  // Timer
  // =====================================
  always_ff @(posedge clk) begin : TIMER
    if (rst_p) begin
      mtime    <= 0;
      mtimecmp <= 64'hffffffffffffffff;
    end else begin
      if (mem_ec == EC_M_TIMER) begin
        mtime <= 0;
      end else if ((mem_state == MEM_MTIME) && (mem_op == OP_SW)) begin
        if (mem_imm == MTIME_LADDR) begin
          mtime[31:0] <= mem_data_o;
        end else if (mem_imm == MTIME_HADDR) begin
          mtime[63:32] <= mem_data_o;
        end
      end else if ((mem_state == MEM_MTIMECMP) && (mem_op == OP_SW)) begin
        if (mem_imm == MTIMECMP_LADDR) begin
          mtimecmp[31:0] <= mem_data_o;
        end else if (mem_imm == MTIMECMP_HADDR) begin
          mtimecmp[63:32] <= mem_data_o;
        end
      end else begin
        if ((privilege == PRIVILEGE_U) && (mtime < mtimecmp)) mtime <= mtime + 1;
      end
    end
  end


endmodule


