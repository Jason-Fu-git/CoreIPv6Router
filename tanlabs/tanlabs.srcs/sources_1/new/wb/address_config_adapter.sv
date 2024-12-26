/*
Address configuration adapter module
This module is used to configure the MAC and IP addresses of the Ethernet cores
@Author: Jason Fu
*/
`include "wb.vh"

module address_config_adapter #(
    parameter dafault_mac_addr_0  = 48'h541069641f8c,
    parameter default_ipv6_addr_0 = 128'h541069feff641f8e00000000000080fe,
    parameter dafault_mac_addr_1  = 48'h551069641f8c,
    parameter default_ipv6_addr_1 = 128'h551069feff641f8e00000000000080fe,
    parameter dafault_mac_addr_2  = 48'h561069641f8c,
    parameter default_ipv6_addr_2 = 128'h561069feff641f8e00000000000080fe,
    parameter dafault_mac_addr_3  = 48'h571069641f8c,
    parameter default_ipv6_addr_3 = 128'h571069feff641f8e00000000000080fe
) (
    input wire eth_clk,
    input wire eth_reset,

    // ip address and mac address
    output reg [3:0][ 47:0] mac_addrs,
    output reg [3:0][127:0] ip_addrs,

    // Wishbone master interface (eth_clk)
    input  wire [31:0] wbm_adr_i,
    input  wire [31:0] wbm_dat_i,
    input  wire [ 3:0] wbm_sel_i,
    input  wire        wbm_stb_i,
    input  wire        wbm_we_i,
    output reg  [31:0] wbm_dat_o,
    output reg         wbm_ack_o
);

  logic [1:0] index;
  assign index = wbm_adr_i[9:8];

  always_comb begin
    wbm_dat_o = 32'd0;
    if (wbm_adr_i[12] == 1'b0) begin
      // IP address
      case (wbm_adr_i[3:0])
        4'h0: wbm_dat_o = ip_addrs[index][31:0];
        4'h4: wbm_dat_o = ip_addrs[index][63:32];
        4'h8: wbm_dat_o = ip_addrs[index][95:64];
        4'hC: wbm_dat_o = ip_addrs[index][127:96];
        default: wbm_dat_o = 32'd0;
      endcase
    end else begin
      // MAC address
      case (wbm_adr_i[3:0])
        4'h0: wbm_dat_o = mac_addrs[index][31:0];
        4'h4: wbm_dat_o = mac_addrs[index][47:32];
        default: wbm_dat_o = 32'd0;
      endcase
    end
  end

  always_ff @(posedge eth_clk) begin
    if (eth_reset) begin
      wbm_ack_o <= 1'b0;
    end else begin
      if (wbm_ack_o) begin
        if (!wbm_stb_i) begin
          wbm_ack_o <= 1'b0;
        end
      end else begin
        if (wbm_stb_i) begin
          wbm_ack_o <= 1'b1;
        end
      end
    end
  end

  always_ff @(posedge eth_clk) begin
    if (eth_reset) begin
      ip_addrs[0] <= default_ipv6_addr_0;
      ip_addrs[1] <= default_ipv6_addr_1;
      ip_addrs[2] <= default_ipv6_addr_2;
      ip_addrs[3] <= default_ipv6_addr_3;

      mac_addrs[0] <= dafault_mac_addr_0;
      mac_addrs[1] <= dafault_mac_addr_1;
      mac_addrs[2] <= dafault_mac_addr_2;
      mac_addrs[3] <= dafault_mac_addr_3;
    end else if (wbm_stb_i && wbm_we_i) begin
      // Write
      if (wbm_adr_i[12] == 1'b0) begin
        // IP address
        case (wbm_adr_i[3:0])
          4'h0: ip_addrs[index][31:0] <= wbm_dat_i;
          4'h4: ip_addrs[index][63:32] <= wbm_dat_i;
          4'h8: ip_addrs[index][95:64] <= wbm_dat_i;
          4'hC: ip_addrs[index][127:96] <= wbm_dat_i;
          default: begin
          end
        endcase
      end else begin
        // MAC address
        case (wbm_adr_i[3:0])
          4'h0: mac_addrs[index][31:0] <= wbm_dat_i;
          4'h4: mac_addrs[index][47:32] <= wbm_dat_i[15:0];
          default: begin
          end
        endcase
      end
    end
  end


endmodule
