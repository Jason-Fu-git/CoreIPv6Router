module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter SRAM_ADDR_WIDTH = 21,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,  // valid
    output reg wb_ack_o,  // ready
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,  // write enable

    // sram interface
    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg sram_ce_n,  // chip enable not
    output reg sram_oe_n,  // output (read) enable not
    output reg sram_we_n,  // write enable not
    output reg [SRAM_BYTES-1:0] sram_be_n  // byte enable not
);

  wire [SRAM_DATA_WIDTH-1:0] sram_data_i;
  reg [SRAM_DATA_WIDTH-1:0] sram_data_o;
  reg sram_data_t;

  assign sram_data = sram_data_t ? 'Z : sram_data_o;
  assign sram_data_o = wb_dat_i;
  assign sram_data_i = sram_data;
  assign wb_dat_o = sram_data_i;

  assign sram_addr = wb_adr_i[SRAM_ADDR_WIDTH+1:2];
  assign sram_be_n = (sram_ce_n) ? 0 : ~wb_sel_i;

  typedef enum logic [3:0] {
    CTL_IDLE,  // Controller Idle
    CTL_RD_1,
    CTL_RD_2,
    CTL_RD_3,
    CTL_WR_1,
    CTL_WR_2,
    CTL_WR_3,
    CTL_WR_4,
    CTL_WR_5
  } state_t;

  state_t state, next_state;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      state <= CTL_IDLE;
    end else begin
      state <= next_state;
    end
  end

  assign wb_ack_o = ((state != CTL_IDLE) && (next_state == CTL_IDLE)) ? 1'b1 : 1'b0;
  assign sram_ce_n = (state == CTL_IDLE) ? 1'b1 : 1'b0;
  assign sram_oe_n = ((state == CTL_RD_1) || (state == CTL_RD_2) || (state == CTL_RD_3)) ? 1'b0 : 1'b1;
  assign sram_we_n = ((state == CTL_WR_1) || (state == CTL_WR_2) || (state == CTL_WR_3) || (state == CTL_WR_4) || (state == CTL_WR_5)) ? 1'b0 : 1'b1;
  assign sram_data_t = sram_we_n ? 1'b1 : 1'b0;

  always_comb begin
    case (state)
      CTL_IDLE: begin
        if (wb_stb_i && wb_cyc_i) begin
          next_state = (wb_we_i ? CTL_WR_1 : CTL_RD_1);
        end else begin
          next_state = CTL_IDLE;
        end
      end
      CTL_RD_1: begin
        next_state = CTL_RD_2;
      end
      CTL_RD_2: begin
        next_state = CTL_RD_3;
      end
      CTL_RD_3: begin
        next_state = CTL_IDLE;
      end
      CTL_WR_1: begin
        next_state = CTL_WR_2;
      end
      CTL_WR_2: begin
        next_state = CTL_WR_3;
      end
      CTL_WR_3: begin
        next_state = CTL_WR_4;
      end
      CTL_WR_4: begin
        next_state = CTL_WR_5;
      end
      CTL_WR_5: begin
        next_state = CTL_IDLE;
      end
      default: begin
        next_state = CTL_IDLE;
      end
    endcase
  end

endmodule
