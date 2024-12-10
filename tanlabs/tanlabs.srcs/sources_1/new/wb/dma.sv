`include "frame_datapath.vh"

module dma #(
    parameter IN_DATA_WIDTH  = 64,
    parameter OUT_DATA_WIDTH = DATAW_WIDTH
) (
    input wire clk,
    input wire rst_p,

    // It is recommended to use a FIFO to buffer the input data.
    input frame_beat in,
    output reg in_ready,

    output frame_beat out,
    input wire out_ready,

    // Attach to SRAM (Need Address Translation)
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

    // Status Registers
    input wire        cpu_stb_i,
    input wire        cpu_we_i,        // Write Enable
    input wire [31:0] cpu_adr_i,       // Address
    input wire [31:0] cpu_dat_width_i, // Data Width (in bytes)

    output reg        dma_ack_o,       // DMA Acknowledge, will be held until STB is de-asserted
    output reg [31:0] dma_dat_width_o  // Data Width (in bytes)
);

  // Considering that we only have one SRAM, DMA cannot execute multiple transactions at the same time
  // So we can use a single state machine to control the whole DMA process

  // State Machine
  typedef enum logic [1:0] {
    IDLE,
    READ,
    WRITE,
    DONE
  } dma_state_t;

  dma_state_t state, next_state;

  frame_beat dm_in, dm_out;
  logic dm_in_ready, dm_out_ready;

  logic [31:0] data_width;
  logic dm_stb_reg;

  always_ff @(posedge clk) begin : STB_REG
    if (rst_p) begin
      dm_stb_reg <= 0;
    end else begin
      dm_stb_reg <= dm_stb_o;
    end
  end

  // Data Width Converter
  frame_beat_width_converter #(IN_DATA_WIDTH, 32) in_width_converter (
      .clk(clk),
      .rst(rst_p),
      .in(in),
      .out(dm_in),
      .in_ready(in_ready),  // out port
      .out_ready(dm_in_ready)  // in port
  );

  logic [31:0] addr;

  always_ff @(posedge clk) begin : SRAMADDR
    if (rst_p) begin
      addr <= 0;
    end else begin
      if ((state == IDLE) && ((next_state == READ) || (next_state == WRITE))) begin
        addr <= cpu_adr_i;
      end else if (dm_ack_i && dm_stb_reg) begin
        addr <= addr + 4;
      end
    end
  end

  // SRAM signals
  assign dm_cyc_o = dm_stb_o;
  assign dm_adr_o = addr;
  assign dm_dat_o = dm_in.data[31:0];
  assign dm_we_o  = (state == WRITE);

  always_comb begin : SRAM_SEL
    dm_sel_o = 4'hF;
    if (state == WRITE) begin
      if (dm_in.last) begin
        dm_sel_o = dm_in.keep[3:0];
      end
    end
  end

  always_comb begin : SRAM_STB
    dm_stb_o = 0;
    if (dm_ack_i) begin
      dm_stb_o = 0;
    end else begin
      case (state)
        READ: begin
          if (!(dm_out.last) && dm_out_ready) begin
            dm_stb_o = 1;
          end else if (dm_stb_reg) begin
            // Guarantee that a request won't be interrupted
            dm_stb_o = 1;
          end
        end
        WRITE: begin
          if (dm_in.valid) begin
            if ((data_width == 0) && dm_in.is_first) begin
              dm_stb_o = 1;
            end else if (data_width > 0) begin
              dm_stb_o = 1;
            end else if (dm_stb_reg) begin
              // Guarantee that a request won't be interrupted
              dm_stb_o = 1;
            end
          end else if (dm_stb_reg) begin
            // Guarantee that a request won't be interrupted
            dm_stb_o = 1;
          end
        end
        default: dm_stb_o = 0;
      endcase
    end
  end


  // State Transfer
  always_comb begin : StateTransfer
    next_state = state;
    case (state)
      IDLE: begin
        if (cpu_stb_i) begin
          if (cpu_we_i) begin
            next_state = WRITE;
          end else begin
            next_state = READ;
          end
        end
      end
      READ: begin
        // Last beat sent
        if (out.last && out.valid) begin
          next_state = DONE;
        end
      end
      WRITE: begin
        // Write complete
        if (dm_ack_i && dm_in.last && dm_stb_reg) begin
          next_state = DONE;
        end
      end
      DONE: begin
        if (!cpu_stb_i) begin
          next_state = IDLE;
        end
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end


  // State Machine
  always_ff @(posedge clk) begin : StateMachine
    if (rst_p) begin
      state      <= IDLE;
      data_width <= 0;
      dm_out     <= 0;
    end else begin
      state <= next_state;
      case (state)
        IDLE: begin
          data_width <= 0;
          dm_out     <= 0;
        end
        READ: begin
          if (dm_ack_i && dm_stb_reg) begin
            data_width   <= data_width + 4;
            // fill in the data
            dm_out.user  <= 0;
            dm_out.valid <= 1;
            if ((data_width + 4) >= cpu_dat_width_i) begin
              dm_out.keep <= cpu_dat_width_i[1:0];
              dm_out.last <= 1;
              case (cpu_dat_width_i[1:0])
                2'd0: dm_out.keep <= 4'b1111;
                2'd1: dm_out.keep <= 4'b0001;
                2'd2: dm_out.keep <= 4'b0011;
                2'd3: dm_out.keep <= 4'b0111;
                default: dm_out.keep <= 4'b1111;
              endcase
              case (cpu_dat_width_i[1:0])
                2'd0: dm_out.data <= dm_dat_i[31:0];
                2'd1: dm_out.data <= dm_dat_i[7:0];
                2'd2: dm_out.data <= dm_dat_i[15:0];
                2'd3: dm_out.data <= dm_dat_i[23:0];
                default: dm_out.data <= dm_dat_i[31:0];
            endcase
            end else begin
              dm_out.keep <= 4'hF;
              dm_out.last <= 0;
              dm_out.data <= dm_dat_i[31:0];
            end
            if (data_width == 0) begin
              dm_out.is_first <= 1;
            end else begin
              dm_out.is_first <= 0;
            end
            // FIXME: Fill in the metadata
            dm_out.meta <= 0;
          end else if (dm_out_ready) begin
            dm_out.valid <= 0;
          end
        end
        WRITE: begin
          if (dm_ack_i && dm_stb_reg) begin
            case (dm_in.keep[3:0])
              4'b1111: data_width <= data_width + 4;
              4'b0111: data_width <= data_width + 3;
              4'b0011: data_width <= data_width + 2;
              4'b0001: data_width <= data_width + 1;
              default: data_width <= data_width + 4;
            endcase
          end
        end
        DONE: begin
          // Do nothing
        end
        default: begin
          // Do nothing
        end
      endcase
    end
  end

  assign dma_ack_o = (state == DONE);
  assign dma_dat_width_o = data_width;
  assign dm_in_ready     = (state == WRITE)
                              && (!dm_stb_o)
                              && (!dm_ack_i || dm_stb_reg)
                              && (next_state != DONE);



  // Data Width Converter
  frame_beat_width_converter #(32, OUT_DATA_WIDTH) out_width_converter (
      .clk(clk),
      .rst(rst_p),
      .in(dm_out),
      .out(out),
      .in_ready(dm_out_ready),
      .out_ready(out_ready)
  );

endmodule

