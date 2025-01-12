module wb_async (
    input wire eth_clk,
    input wire eth_reset,
    input wire core_clk,
    input wire core_reset,

    // Wishbone master interface (core_clk)
    input  wire [31:0] wbm_adr_i,
    input  wire [31:0] wbm_dat_i,
    input  wire [ 3:0] wbm_sel_i,
    input  wire        wbm_stb_i,
    input  wire        wbm_we_i,
    output reg  [31:0] wbm_dat_o,
    output reg         wbm_ack_o,


    // Wishbone slave interface (eth_clk)
    output reg  [31:0] wbs_adr_o,
    output reg  [31:0] wbs_dat_o,
    output reg  [ 3:0] wbs_sel_o,
    output reg         wbs_stb_o,
    output reg         wbs_we_o,
    input  wire [31:0] wbs_dat_i,
    input  wire        wbs_ack_i
);
  assign wbs_sel_o = 4'b1111;

  reg wbm_stb_prev;
  always_ff @(posedge core_clk) begin
    if (core_reset) begin
      wbm_stb_prev <= 1'b0;
    end else begin
      wbm_stb_prev <= wbm_stb_i;
    end
  end

  reg wbs_ack_prev;
  always_ff @(posedge eth_clk) begin
    if (eth_reset) begin
      wbs_ack_prev <= 1'b0;
    end else begin
      wbs_ack_prev <= wbs_ack_i;
    end
  end

  reg valid_core;
  always_ff @(posedge core_clk) begin
    if (core_reset) begin
      wbm_ack_o <= 1'b0;
    end else begin
      if (wbm_ack_o) begin
        if (!wbm_stb_i) begin
          wbm_ack_o <= 1'b0;
        end
      end else begin
        if (valid_core) begin
          wbm_ack_o <= 1'b1;
        end
      end
    end
  end

  reg valid_eth;
  always_ff @(posedge eth_clk) begin
    if (eth_reset) begin
      wbs_stb_o <= 1'b0;
    end else begin
      if (wbs_stb_o) begin
        if (wbs_ack_i) begin
          wbs_stb_o <= 1'b0;
        end
      end else begin
        if (valid_eth) begin
          wbs_stb_o <= 1'b1;
        end
      end
    end
  end


  axis_data_async_fifo_wb_cte axis_data_async_fifo_wb_cte_i (
      .s_axis_aresetn(~core_reset),                     // input wire s_axis_aresetn
      .s_axis_aclk   (core_clk),                        // input wire s_axis_aclk
      .s_axis_tvalid ((!wbm_stb_prev) && (wbm_stb_i)),  // input wire s_axis_tvalid
      .s_axis_tready (),                                // output wire s_axis_tready
      .s_axis_tdata  ({wbm_adr_i, wbm_dat_i}),          // input wire [63 : 0] s_axis_tdata
      .s_axis_tuser  (wbm_we_i),                        // input wire [0 : 0] s_axis_tuser
      // .m_axis_aclk   (eth_clk),                         // input wire m_axis_aclk
      .m_axis_tvalid (valid_eth),                       // output wire m_axis_tvalid
      .m_axis_tready (1'b1),                            // input wire m_axis_tready
      .m_axis_tdata  ({wbs_adr_o, wbs_dat_o}),          // output wire [63 : 0] m_axis_tdata
      .m_axis_tuser  (wbs_we_o)                         // output wire [0 : 0] m_axis_tuser
  );


  axis_data_async_fifo_wb_etc axis_data_async_fifo_wb_etc_i (
      .s_axis_aresetn(~eth_reset),                      // input wire s_axis_aresetn
      .s_axis_aclk   (eth_clk),                         // input wire s_axis_aclk
      .s_axis_tvalid ((!wbs_ack_prev) && (wbs_ack_i)),  // input wire s_axis_tvalid
      .s_axis_tready (),                                // output wire s_axis_tready
      .s_axis_tdata  (wbs_dat_i),                       // input wire [31 : 0] s_axis_tdata
      // .m_axis_aclk   (core_clk),                        // input wire m_axis_aclk
      .m_axis_tvalid (valid_core),                      // output wire m_axis_tvalid
      .m_axis_tready (1'b1),                            // input wire m_axis_tready
      .m_axis_tdata  (wbm_dat_o)                        // output wire [31 : 0] m_axis_tdata
  );


endmodule
