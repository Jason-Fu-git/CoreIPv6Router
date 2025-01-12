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
    output reg  [  1:0] r_port_id,

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
  typedef struct packed {
    logic [127:0] nexthop;
    logic [1:0]   port_id;
  } nexthop_table_entry_t;
  nexthop_table_entry_t [31:0] nexthop_table_entries;

  // read operation
  assign r_nexthop = nexthop_table_entries[r_addr].nexthop;
  assign r_port_id = nexthop_table_entries[r_addr].port_id;

  // Wishbone slave (eth_clk)
  logic [4:0] index;
  assign index = wbm_adr_i[8:4];

  always_comb begin
    wbm_dat_o = 32'd0;
    if (wbm_adr_i[12]) begin
      // port_id
      wbm_dat_o = {30'd0, nexthop_table_entries[index].port_id};
    end else begin
      // nexthop
      case (wbm_adr_i[3:0])
        4'h0: wbm_dat_o = nexthop_table_entries[index].nexthop[31:0];
        4'h4: wbm_dat_o = nexthop_table_entries[index].nexthop[63:32];
        4'h8: wbm_dat_o = nexthop_table_entries[index].nexthop[95:64];
        4'hC: wbm_dat_o = nexthop_table_entries[index].nexthop[127:96];
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
      for (int i = 0; i < 32; i++) begin
        nexthop_table_entries[i] <= 0;
      end
    end else if (wbm_stb_i && wbm_we_i) begin
      // Write
      if (wbm_adr_i[12]) begin
        // port_id
        nexthop_table_entries[index].port_id <= wbm_dat_i[1:0];
      end else begin
        // nexthop
        case (wbm_adr_i[3:0])
          4'h0: nexthop_table_entries[index].nexthop[31:0] <= wbm_dat_i;
          4'h4: nexthop_table_entries[index].nexthop[63:32] <= wbm_dat_i;
          4'h8: nexthop_table_entries[index].nexthop[95:64] <= wbm_dat_i;
          4'hC: nexthop_table_entries[index].nexthop[127:96] <= wbm_dat_i;
          default: begin
          end
        endcase
      end
    end
  end



endmodule
