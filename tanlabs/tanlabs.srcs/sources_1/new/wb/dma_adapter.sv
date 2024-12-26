`include "wb.vh"
module dma_adapter (
    input wire clk,
    input wire rst,

    // Wishbone master interface
    input  wire [31:0] wbm_adr_i,
    input  wire [31:0] wbm_dat_i,
    input  wire [ 3:0] wbm_sel_i,
    input  wire        wbm_stb_i,
    input  wire        wbm_we_i,
    output reg  [31:0] wbm_dat_o,
    output reg         wbm_ack_o,

    // DMA Register interface
    input  wire        dma_ack_i,
    input  wire [31:0] dma_dat_width_i,
    input  wire [15:0] dma_checksum_i,
    input  wire [ 1:0] dma_port_id_i,
    output reg  [31:0] dma_cpu_addr_o,
    output reg  [31:0] dma_cpu_dat_width_o,
    output reg         dma_cpu_stb_o,
    output reg         dma_cpu_we_o
);

  always_comb begin : READ
    wbm_dat_o = 32'h0;
    case (wbm_adr_i)
      DMA_CPU_STB:        wbm_dat_o = dma_cpu_stb_o;
      DMA_CPU_WE:         wbm_dat_o = dma_cpu_we_o;
      DMA_CPU_ADDR:       wbm_dat_o = dma_cpu_addr_o;
      DMA_CPU_DATA_WIDTH: wbm_dat_o = dma_cpu_dat_width_o;
      DMA_ACK:            wbm_dat_o = dma_ack_i;
      DMA_DATA_WIDTH:     wbm_dat_o = dma_dat_width_i;
      DMA_CHECKSUM:       wbm_dat_o = {16'd0, dma_checksum_i};
      DMA_PORT_ID:        wbm_dat_o = {30'd0, dma_port_id_i};
      default:            wbm_dat_o = 32'h0;
    endcase
  end

  always_ff @(posedge clk) begin : ACK
    if (rst) begin
      wbm_ack_o <= 1'b0;
    end else if (wbm_stb_i) begin
      wbm_ack_o <= 1'b1;
    end else begin
      wbm_ack_o <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin : WRITE
    if (rst) begin
      dma_cpu_addr_o      <= 32'h0;
      dma_cpu_dat_width_o <= 32'h0;
      dma_cpu_stb_o       <= 1'b0;
      dma_cpu_we_o        <= 1'b0;
    end else if (wbm_stb_i) begin
      case (wbm_adr_i)
        DMA_CPU_STB:        dma_cpu_stb_o <= wbm_dat_i;
        DMA_CPU_WE:         dma_cpu_we_o <= wbm_dat_i;
        DMA_CPU_ADDR:       dma_cpu_addr_o <= wbm_dat_i;
        DMA_CPU_DATA_WIDTH: dma_cpu_dat_width_o <= wbm_dat_i;
        default:            ;
      endcase
    end
  end


endmodule
