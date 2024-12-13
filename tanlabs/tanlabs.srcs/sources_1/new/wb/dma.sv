`include "frame_datapath.vh"

module dma #(
    parameter IN_DATA_WIDTH  = DATAW_WIDTH,
    parameter OUT_DATA_WIDTH = DATAW_WIDTH
) (
    input wire eth_clk,
    input wire eth_rst,

    input wire core_clk,
    input wire core_rst,

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

  logic [31:0] data_width;
  logic dm_stb_reg;

  frame_beat in_conv_o, out_conv_i;
  logic in_filter_ready;
  logic in_fifo_ready;
  logic out_conv_ready;
  logic in_dm_ready, out_dm_ready;

  reg [31:0] filtered_in_data;
  reg [3:0] filtered_in_keep;
  reg filtered_in_last;
  reg filtered_in_valid;

  reg [31:0] fifo_in_data;
  reg [3:0] fifo_in_keep;
  reg fifo_in_last;
  reg fifo_in_valid;
  reg fifo_in_prog_full;

  reg [31:0] fifo_out_data;
  reg [3:0] fifo_out_keep;
  reg fifo_out_last;
  reg fifo_out_valid;

  always_ff @(posedge core_clk) begin : STB_REG
    if (core_rst) begin
      dm_stb_reg <= 0;
    end else begin
      dm_stb_reg <= dm_stb_o;
    end
  end


  // ================================
  // Input Data Width Converter and FIFO
  // ================================

  // Data Width Converter
  frame_beat_width_converter #(IN_DATA_WIDTH, 32) in_width_converter (
      .clk(eth_clk),
      .rst(eth_rst),
      .in(in),
      .out(in_conv_o),
      .in_ready(in_ready),  // out port
      .out_ready(in_filter_ready)  // in port
  );

  // We use a FIFO to buffer the input data, so we always accept the input data
  assign in_filter_ready = 1'b1;

  reg in_is_first;
  always @(posedge eth_clk) begin
    if (eth_rst) begin
      in_is_first <= 1'b1;
    end else begin
      if (in_conv_o.valid && in_filter_ready) begin
        in_is_first <= in_conv_o.last;
      end
    end
  end

  reg in_drop_by_prev;  // Dropped by the previous frame?
  always @(posedge eth_clk) begin
    if (eth_rst) begin
      in_drop_by_prev <= 1'b0;
    end else begin
      if (in_is_first && in_conv_o.valid && in_filter_ready) begin
        in_drop_by_prev <= in_conv_o.meta.drop_next;
      end
    end
  end


  frame_filter #(
      .DATA_WIDTH(DATAW_WIDTH),
      .ID_WIDTH  (ID_WIDTH)
  ) frame_filter_i (
      .eth_clk(eth_clk),
      .reset  (eth_rst),

      .s_data(in_conv_o.data),
      .s_keep(in_conv_o.keep),
      .s_last(in_conv_o.last),
      .s_user(in_conv_o.user),
      .s_id(),
      .s_valid(in_conv_o.valid),
      .s_ready(),

      .drop(in_conv_o.meta.drop || in_drop_by_prev || fifo_in_prog_full),

      .m_data(filtered_in_data),
      .m_keep(filtered_in_keep),
      .m_last(filtered_in_last),
      .m_user(),
      .m_id(),
      .m_valid(filtered_in_valid),
      .m_ready(in_fifo_ready)
  );

  axis_data_async_fifo_dma axis_data_async_fifo_dma_in_i (
      .s_axis_aresetn(~eth_rst),           // input wire s_axis_aresetn
      .s_axis_aclk   (eth_clk),            // input wire s_axis_aclk
      .s_axis_tvalid (filtered_in_valid),  // input wire s_axis_tvalid
      .s_axis_tready (in_fifo_ready),      // output wire s_axis_tready
      .s_axis_tdata  (filtered_in_data),   // input wire [31 : 0] s_axis_tdata
      .s_axis_tkeep  (filtered_in_keep),   // input wire [3 : 0] s_axis_tkeep
      .s_axis_tlast  (filtered_in_last),   // input wire s_axis_tlast

      .m_axis_aclk  (core_clk),       // input wire m_axis_aclk
      .m_axis_tvalid(fifo_in_valid),  // output wire m_axis_tvalid
      .m_axis_tready(in_dm_ready),    // input wire m_axis_tready
      .m_axis_tdata (fifo_in_data),   // output wire [31 : 0] m_axis_tdata
      .m_axis_tkeep (fifo_in_keep),   // output wire [3 : 0] m_axis_tkeep
      .m_axis_tlast (fifo_in_last),   // output wire m_axis_tlast

      .prog_full(fifo_in_prog_full)  // output wire prog_full
  );

  reg fifo_in_is_first;
  always @(posedge core_clk) begin
    if (core_rst) begin
      fifo_in_is_first <= 1'b1;
    end else begin
      if (fifo_in_valid && in_dm_ready) begin
        fifo_in_is_first <= fifo_in_last;
      end
    end
  end
  // ================================



  // ================================
  // DMA
  // ================================
  logic [31:0] addr;

  always_ff @(posedge core_clk) begin : SRAMADDR
    if (core_rst) begin
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
  assign dm_dat_o = fifo_in_data[31:0];
  assign dm_we_o  = (state == WRITE);

  always_comb begin : SRAM_SEL
    dm_sel_o = 4'hF;
    if (state == WRITE) begin
      if (fifo_in_last) begin
        dm_sel_o = fifo_in_keep[3:0];
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
          if (!(fifo_out_last) && out_dm_ready) begin
            dm_stb_o = 1;
          end else if (dm_stb_reg) begin
            // Guarantee that a request won't be interrupted
            dm_stb_o = 1;
          end
        end
        WRITE: begin
          if (fifo_in_valid) begin
            if ((data_width == 0) && fifo_in_is_first) begin
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
        if ((data_width >= cpu_dat_width_i) && out_dm_ready) begin
          next_state = DONE;
        end
      end
      WRITE: begin
        // Write complete
        if (dm_ack_i && fifo_in_last && dm_stb_reg) begin
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
  always_ff @(posedge core_clk) begin : StateMachine
    if (core_rst) begin
      state          <= IDLE;
      data_width     <= 0;
      fifo_out_data  <= 0;
      fifo_out_keep  <= 0;
      fifo_out_last  <= 0;
      fifo_out_valid <= 0;
    end else begin
      state <= next_state;
      case (state)
        IDLE: begin
          // Reserve the data width
          if (next_state != IDLE) begin
            data_width <= 0;
          end
          fifo_out_data  <= 0;
          fifo_out_keep  <= 0;
          fifo_out_last  <= 0;
          fifo_out_valid <= 0;
        end
        READ: begin
          if (dm_ack_i && dm_stb_reg) begin
            data_width <= data_width + 4;
            // fill in the data
            fifo_out_valid <= 1;
            if ((data_width + 4) >= cpu_dat_width_i) begin
              fifo_out_last <= 1;
              case (cpu_dat_width_i[1:0])
                2'd0: fifo_out_keep <= 4'b1111;
                2'd1: fifo_out_keep <= 4'b0001;
                2'd2: fifo_out_keep <= 4'b0011;
                2'd3: fifo_out_keep <= 4'b0111;
                default: fifo_out_keep <= 4'b1111;
              endcase
              case (cpu_dat_width_i[1:0])
                2'd0: fifo_out_data <= dm_dat_i[31:0];
                2'd1: fifo_out_data <= dm_dat_i[7:0];
                2'd2: fifo_out_data <= dm_dat_i[15:0];
                2'd3: fifo_out_data <= dm_dat_i[23:0];
                default: fifo_out_data <= dm_dat_i[31:0];
              endcase
            end else begin
              fifo_out_keep <= 4'hF;
              fifo_out_last <= 0;
              fifo_out_data <= dm_dat_i[31:0];
            end
            // if (data_width == 0) begin
            //   dm_out.is_first <= 1;
            // end else begin
            //   dm_out.is_first <= 0;
            // end
          end else if (out_dm_ready) begin
            fifo_out_valid <= 0;
          end
        end
        WRITE: begin
          if (dm_ack_i && dm_stb_reg) begin
            case (fifo_in_keep[3:0])
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
  assign in_dm_ready     = (state == WRITE)
                              && (!dm_stb_o)
                              && (!dm_ack_i || dm_stb_reg)
                              && (next_state != DONE);



  // ================================
  // Output Data Width Converter and FIFO
  // ================================

  axis_data_async_fifo_dma axis_data_async_fifo_dma_out_i (
      .s_axis_aresetn(~core_rst),       // input wire s_axis_aresetn
      .s_axis_aclk   (core_clk),        // input wire s_axis_aclk
      .s_axis_tvalid (fifo_out_valid),  // input wire s_axis_tvalid
      .s_axis_tready (out_dm_ready),    // output wire s_axis_tready
      .s_axis_tdata  (fifo_out_data),   // input wire [31 : 0] s_axis_tdata
      .s_axis_tkeep  (fifo_out_keep),   // input wire [3 : 0] s_axis_tkeep
      .s_axis_tlast  (fifo_out_last),   // input wire s_axis_tlast

      .m_axis_aclk  (eth_clk),           // input wire m_axis_aclk
      .m_axis_tvalid(out_conv_i.valid),  // output wire m_axis_tvalid
      .m_axis_tready(out_conv_ready),    // input wire m_axis_tready
      .m_axis_tdata (out_conv_i.data),   // output wire [31 : 0] m_axis_tdata
      .m_axis_tkeep (out_conv_i.keep),   // output wire [3 : 0] m_axis_tkeep
      .m_axis_tlast (out_conv_i.last),   // output wire m_axis_tlast

      .prog_full()  // output wire prog_full
  );

  always @(posedge eth_clk) begin
    if (eth_rst) begin
      out_conv_i.is_first <= 1'b1;
      out_conv_i.user     <= 0;
      out_conv_i.meta     <= 0;
    end else begin
      if (out_conv_i.valid && out_conv_ready) begin
        out_conv_i.is_first <= out_conv_i.last;
        out_conv_i.user     <= 0;
        out_conv_i.meta     <= 0;
      end
    end
  end

  // Data Width Converter
  frame_beat_width_converter #(32, OUT_DATA_WIDTH) out_width_converter (
      .clk(eth_clk),
      .rst(eth_rst),
      .in(out_conv_i),
      .out(out),
      .in_ready(out_conv_ready),
      .out_ready(out_ready)
  );
  // ================================

endmodule

