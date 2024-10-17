`timescale 1ns / 1ps

/**
*  @brief  BRAM IO Controller
*  @note
*
*   Timing:
*   - Both read and write costs **2 cycles**.
*   - When read or write is completed, ack_p is set to 1 for **1 cycle**.
*
*   Input Specification:
*   - Only one of rea_p and wea_p can be set to 1 at a time.
*   - When wea_p or rea_p is set to 1, the address and data must not be changed.
*   - The address and data are valid when ack_p is 1.
*   - FIXME: Between two successive queries, rea_p and wea_p should be 0.
*
*  @author Jason Fu
*
*/

module bram_controller #(
    parameter DATA_WIDTH = 320,
    parameter ADDR_WIDTH = 5
) (
    // clk and reset
    input wire clk,
    input wire rst_p,

    // control signals
    input  wire rea_p,  // chip enable for this bram
    input  wire wea_p,  // write enable for this bram
    output reg  ack_p,  // acknowledge signal

    // address and data
    input  wire [ADDR_WIDTH-1:0] bram_addr_r,  // address for read
    input  wire [ADDR_WIDTH-1:0] bram_addr_w,  // address for write
    input  wire [DATA_WIDTH-1:0] bram_data_w,  // data for write
    output reg  [DATA_WIDTH-1:0] bram_data_r   // data for read
);

  // State Definition
  typedef enum logic {
    ST_IDLE,
    ST_WAIT
  } state_t;
  state_t state;


  // Trigger
  reg prev_rea_p;
  reg prev_wea_p;
  reg trigger;
  assign trigger = (rea_p && !prev_rea_p) || (wea_p && !prev_wea_p);
  always_ff @(posedge clk) begin
    if (rst_p) begin
      prev_rea_p <= 1'b0;
      prev_wea_p <= 1'b0;
    end else begin
      prev_rea_p <= rea_p;
      prev_wea_p <= wea_p;
    end
  end


  // BRAM
  blk_mem_ftb ftb (
      .clka(clk),  // input wire clka
      .ena(!rea_p),  // input wire ena
      .wea(wea_p),  // input wire [0 : 0] wea
      .addra(bram_addr_w),  // input wire [4 : 0] addra
      .dina(bram_data_w),  // input wire [319 : 0] dina
      .clkb(clk),  // input wire clkb
      .enb(rea_p),  // input wire enb
      .addrb(bram_addr_r),  // input wire [4 : 0] addrb
      .doutb(bram_data_r)  // output wire [319 : 0] doutb
  );


  // State Transfer
  always_ff @(posedge clk) begin
    if (rst_p) begin
      state <= ST_IDLE;
      ack_p <= 1'b0;
    end else begin
      case (state)
        ST_IDLE: begin
          if (trigger) begin
            state <= ST_WAIT;
          end else begin
            state <= ST_IDLE;
          end
          ack_p <= 1'b0;
        end
        ST_WAIT: begin
          state <= ST_IDLE;
          ack_p <= 1'b1;
        end
        default: state <= ST_IDLE;
      endcase
    end
  end

endmodule
