`timescale 1ps / 1ps

module tb #(
    parameter FAST_BEHAV = 1,   // Fast behavior simulation?
    parameter DATA_WIDTH = 64,
    parameter ID_WIDTH   = 3
) ();

  parameter BASE_RAM_INIT_FILE = "D:\\Programming\\VivadoProjects\\joint-lab-g5\\firmware\\kernel.bin";

  wire txd;
  wire rxd;

  wire [31:0] base_ram_data;
  wire [19:0] base_ram_addr;
  wire [3:0] base_ram_be_n;
  wire base_ram_ce_n;
  wire base_ram_oe_n;
  wire base_ram_we_n;

  reg reset;
  initial begin
    reset = 1;
    #86000 reset = 0;
  end

  wire clk_125M;

  clock clock_i (.clk_125M(clk_125M));

  wire [3:0] sfp_tb2dut_p;
  wire [3:0] sfp_tb2dut_n;
  wire [3:0] sfp_dut2tb_p;
  wire [3:0] sfp_dut2tb_n;

  generate
    if (!FAST_BEHAV) begin : sfp_model
      wire [DATA_WIDTH - 1:0] in_data;
      wire [DATA_WIDTH / 8 - 1:0] in_keep;
      wire in_last;
      wire [DATA_WIDTH / 8 - 1:0] in_user;
      wire [ID_WIDTH - 1:0] in_id;
      wire in_valid;
      wire in_ready;

      axis_model axis_model_i (
          .clk  (clk_125M),
          .reset(reset),

          .m_data(in_data),
          .m_keep(in_keep),
          .m_last(in_last),
          .m_user(in_user),
          .m_id(in_id),
          .m_valid(in_valid),
          .m_ready(in_ready)
      );

      wire [DATA_WIDTH - 1:0] out_data;
      wire [DATA_WIDTH / 8 - 1:0] out_keep;
      wire out_last;
      wire [DATA_WIDTH / 8 - 1:0] out_user;
      wire [ID_WIDTH - 1:0] out_dest;
      wire out_valid;
      wire out_ready;

      sim_axis2sfp sim_axis2sfp_i (
          .reset(reset),
          .clk_125M(clk_125M),

          .s_data (in_data),
          .s_keep (in_keep),
          .s_last (in_last),
          .s_user (in_user),
          .s_dest (in_id),
          .s_valid(in_valid),
          .s_ready(in_ready),

          .m_data(out_data),
          .m_keep(out_keep),
          .m_last(out_last),
          .m_user(out_user),
          .m_id(out_dest),
          .m_valid(out_valid),
          .m_ready(out_ready),

          .sfp_rx_p(sfp_dut2tb_p),
          .sfp_rx_n(sfp_dut2tb_n),
          .sfp_tx_p(sfp_tb2dut_p),
          .sfp_tx_n(sfp_tb2dut_n)
      );

      axis_receiver axis_receiver_i (
          .clk  (clk_125M),
          .reset(reset),

          .s_data (out_data),
          .s_keep (out_keep),
          .s_last (out_last),
          .s_user (out_user),
          .s_dest (out_dest),
          .s_valid(out_valid),
          .s_ready(out_ready)
      );
    end else begin
      assign sfp_tb2dut_p = 0;
      assign sfp_tb2dut_n = 0;
    end
  endgenerate

  tanlabs #(
      .SIM(FAST_BEHAV)
  ) dut (
      .RST(reset),

      .gtclk_125_p(clk_125M),
      .gtclk_125_n(~clk_125M),

      .led(),

      .uart_tx(txd),
      .uart_rx(rxd),

      .sfp_rx_los(4'd0),
      .sfp_rx_p(sfp_tb2dut_p),
      .sfp_rx_n(sfp_tb2dut_n),
      .sfp_tx_dis(),
      .sfp_tx_p(sfp_dut2tb_p),
      .sfp_tx_n(sfp_dut2tb_n),
      .sfp_link(),
      .sfp_act(),

      .sfp_sda(1'b0),
      .sfp_scl(1'b0),

      .base_ram_data(base_ram_data),
      .base_ram_addr(base_ram_addr),
      .base_ram_ce_n(base_ram_ce_n),
      .base_ram_oe_n(base_ram_oe_n),
      .base_ram_we_n(base_ram_we_n),
      .base_ram_be_n(base_ram_be_n)
  );

  sram_model base1 (
      .DataIO(base_ram_data[15:0]),
      .Address(base_ram_addr[19:0]),
      .OE_n(base_ram_oe_n),
      .CE_n(base_ram_ce_n),
      .WE_n(base_ram_we_n),
      .LB_n(base_ram_be_n[0]),
      .UB_n(base_ram_be_n[1])
  );

  sram_model base2 (
      .DataIO(base_ram_data[31:16]),
      .Address(base_ram_addr[19:0]),
      .OE_n(base_ram_oe_n),
      .CE_n(base_ram_ce_n),
      .WE_n(base_ram_we_n),
      .LB_n(base_ram_be_n[2]),
      .UB_n(base_ram_be_n[3])
  );

  // 直连串口仿真模型
  uart_model uart (
      .rxd(txd),
      .txd(rxd)
  );

  // 从文件加�? BaseRAM
  initial begin
    reg [31:0] tmp_array[0:1048575];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(BASE_RAM_INIT_FILE, "rb");
    if (!n_File_ID) begin
      n_Init_Size = 0;
      $display("Failed to open BaseRAM init file");
    end else begin
      n_Init_Size = $fread(tmp_array, n_File_ID);
      n_Init_Size /= 4;
      $fclose(n_File_ID);
    end
    $display("BaseRAM Init Size(words): %d", n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
      base1.mem_array0[i] = tmp_array[i][24+:8];
      base1.mem_array1[i] = tmp_array[i][16+:8];
      base2.mem_array0[i] = tmp_array[i][8+:8];
      base2.mem_array1[i] = tmp_array[i][0+:8];
    end
  end

endmodule
