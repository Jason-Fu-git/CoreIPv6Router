module uart_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,

    parameter CLK_FREQ = 50_000_000,
    parameter BAUD = 115200
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // uart interface
    // output reg uart_txd_o,
    input  wire uart_rxd_i,
    output wire [6:0] dpy0,
    output wire [6:0] dpy1
);

  localparam REG_DATA = 8'h00;
  localparam REG_STATUS = 8'h05;

  // uart transmitter
//   logic txd_start;
  logic txd_busy;
//   logic [7:0] txd_data;

//   async_transmitter #(
//       .ClkFrequency(CLK_FREQ),
//       .Baud        (BAUD)
//   ) u_async_transmitter (
//       .clk      (clk_i),
//       .TxD_start(txd_start),
//       .TxD_data (txd_data),
//       .TxD      (uart_txd_o),
//       .TxD_busy (txd_busy)
//   );

  // uart receiver
  logic rxd_data_ready;
  logic [7:0] rxd_data;
  logic rxd_clear;

  async_receiver #(
      .ClkFrequency(CLK_FREQ),
      .Baud        (BAUD)
  ) u_async_receiver (
      .clk           (clk_i),
      .RxD           (uart_rxd_i),
      .RxD_data_ready(rxd_data_ready),
      .RxD_clear     (rxd_clear),
      .RxD_data      (rxd_data)
  );

  /*-- internal registers --*/
  wire [7:0] reg_status = {2'b0, ~txd_busy, 4'b0, rxd_data_ready};

  /*-- wishbone fsm --*/
  always_ff @(posedge clk_i) begin
    if (rst_i)
      wb_ack_o <= 0;
    else
      // every request get ACK-ed immediately
      if (wb_ack_o) begin
        wb_ack_o <= 0;
      end else begin
        wb_ack_o <= wb_stb_i;
      end
  end


  // write logic
  logic [13:0] dpys;
  assign dpy0 = dpys[6:0];
  assign dpy1 = dpys[13:7];

  int counter;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      dpys <= 14'b0;
      txd_busy <= 0;
    end else begin
        if (counter != 0) begin
            counter <= counter - 1;
        end else begin
            txd_busy <= 0;
        end
        if(wb_stb_i && wb_we_i) begin
            case (wb_adr_i[7:0])
                REG_DATA: begin
                    txd_busy <= 1;
                    counter <= 62500000; // 500ms
                    if(wb_sel_i[0]) begin
                        case(wb_dat_i[7:0])
                            8'h00: dpys <= 14'b0000000_0000000;
                            8'h0a: dpys <= 14'b0001000_0001000;
                            8'h20: dpys <= 14'b0000000_0001000;
                            8'h2d: dpys <= 14'b0000000_0000001;
                            8'h2f: dpys <= 14'b0000000_0100101;
                            8'h30: dpys <= 14'b1111110_0000000;
                            8'h31: dpys <= 14'b0110000_0000000;
                            8'h32: dpys <= 14'b1101101_0000000;
                            8'h33: dpys <= 14'b1111001_0000000;
                            8'h34: dpys <= 14'b0110011_0000000;
                            8'h35: dpys <= 14'b1011011_0000000;
                            8'h36: dpys <= 14'b1011111_0000000;
                            8'h37: dpys <= 14'b1110000_0000000;
                            8'h38: dpys <= 14'b1111111_0000000;
                            8'h39: dpys <= 14'b1111011_0000000;
                            8'h41: dpys <= 14'b0000000_1110111;
                            8'h43: dpys <= 14'b0000000_1001110;
                            8'h44: dpys <= 14'b0000000_0111101;
                            8'h45: dpys <= 14'b0000000_1001111;
                            8'h46: dpys <= 14'b0000000_1000111;
                            8'h49: dpys <= 14'b0000000_0010000;
                            8'h50: dpys <= 14'b0000000_1100111;
                            8'h51: dpys <= 14'b0000000_1110011;
                            8'h54: dpys <= 14'b0000000_0001111;
                            8'h5b: dpys <= 14'b0000000_0001110;
                            8'h5d: dpys <= 14'b0000000_0111000;
                            8'h74: dpys <= 14'b0000000_0001111;
                            default: dpys <= 14'b1001001_1001001;
                        endcase
                    end
                end
                default: ;  // do nothing
            endcase
        end
    //   txd_start <= 0;
    end
  end

  // read logic
  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      rxd_clear <= 1;  // clear rxd to initialize dataready
    end else if(wb_stb_i && !wb_we_i) begin
      case (wb_adr_i[7:0])
        REG_DATA: begin
          if (wb_sel_i[0]) wb_dat_o[7:0] <= rxd_data;
          if (wb_sel_i[1]) wb_dat_o[15:8] <= rxd_data;
          if (wb_sel_i[2]) wb_dat_o[23:16] <= rxd_data;
          if (wb_sel_i[3]) wb_dat_o[31:24] <= rxd_data;

          rxd_clear <= 1;
        end

        REG_STATUS: begin
          if (wb_sel_i[0]) wb_dat_o[7:0] <= reg_status;
          if (wb_sel_i[1]) wb_dat_o[15:8] <= reg_status;
          if (wb_sel_i[2]) wb_dat_o[23:16] <= reg_status;
          if (wb_sel_i[3]) wb_dat_o[31:24] <= reg_status;
        end

        default: ;  // do nothing
      endcase
    end else begin
      rxd_clear <= 0;
    end
  end

endmodule
