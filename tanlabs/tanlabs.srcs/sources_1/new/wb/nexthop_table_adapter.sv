`timescale 1ns / 1ps

/**
* nexthop_table that stores the nexthop and interface for each destination
* address. The table is implemented as a 32-entry 5-bit wide table.
*
* @author Jason Fu
*
*/
module nexthop_table_adapter (
    input wire eth_clk,
    input wire eth_reset,

    // reading interface (within the same clock cycle)
    input  wire [  4:0] r_addr,
    output reg  [127:0] r_nexthop,

    // Wishbone master interface (eth_clk)
    input  wire [31:0] wbm_adr_i,
    input  wire [31:0] wbm_dat_i,
    input  wire [ 3:0] wbm_sel_i,
    input  wire        wbm_stb_i,
    input  wire        wbm_we_i,
    output reg  [31:0] wbm_dat_o,
    output reg         wbm_ack_o
);

  // table
  reg [31:0][127:0] nexthop_table_entries;

  // read operation
  assign r_nexthop = nexthop_table_entries[r_addr];

  // Wishbone slave (eth_clk)
  logic [4:0] index;
  assign index = wbm_adr_i[12:8];

  always_comb begin
    wbm_dat_o = 32'd0;
    case (wbm_adr_i[3:0])
      4'h0: wbm_dat_o = nexthop_table_entries[index][31:0];
      4'h4: wbm_dat_o = nexthop_table_entries[index][63:32];
      4'h8: wbm_dat_o = nexthop_table_entries[index][95:64];
      4'hC: wbm_dat_o = nexthop_table_entries[index][127:96];
      default: wbm_dat_o = 32'd0;
    endcase
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
      for (int i = 0; i < 32; i++) begin
        nexthop_table_entries[i] <= 128'd0;
      end
    end else if (wbm_stb_i && wbm_we_i) begin
      // Write
      case (wbm_adr_i[3:0])
        4'h0: nexthop_table_entries[index][31:0] <= wbm_dat_i;
        4'h4: nexthop_table_entries[index][63:32] <= wbm_dat_i;
        4'h8: nexthop_table_entries[index][95:64] <= wbm_dat_i;
        4'hC: nexthop_table_entries[index][127:96] <= wbm_dat_i;
        default: begin
        end
      endcase
    end
  end



endmodule
