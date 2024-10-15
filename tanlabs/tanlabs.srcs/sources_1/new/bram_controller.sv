`timescale 1ns / 1ps
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
  typedef enum logic [1:0] {
    ST_IDLE,
    ST_WAIT
  } state_t;
  state_t state;

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


  // 状态转移逻辑
  always_ff @(posedge clk) begin : StateTransfer
    if (rst_p) begin
      state <= ST_IDLE;
      ack_p <= 1'b0;
    end else begin
      case (state)
        ST_IDLE: begin
          if (cea_p) begin
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
