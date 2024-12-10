`timescale 1ns / 1ps

/**
* nexthop_table that stores the nexthop and interface for each destination
* address. The table is implemented as a 32-entry 5-bit wide table.
*
* @author Jason Fu
*
*/

module nexthop_table (
    input wire clk,
    input wire rst_p,

    // writing interface (for the next clock cycle)
    input wire [4:0] w_addr,
    input wire [127:0] w_nexthop,
    input wire [1:0] w_iface,
    input wire wea_p,

    // reading interface (within the same clock cycle)
    input  wire [  4:0] r_addr,
    output reg  [127:0] r_nexthop,
    output reg  [  1:0] r_iface
);

  // table entry
  typedef struct packed {
    logic [127:0] nexthop;
    logic [1:0]   iface;
  } nexthop_table_entry_t;

  // table
  nexthop_table_entry_t nexthop_table_entries[32];

  // read operation
  always_comb begin : Read
    r_nexthop = nexthop_table_entries[r_addr].nexthop;
    r_iface   = nexthop_table_entries[r_addr].iface;
  end

  // write operation
  always_ff @(posedge clk) begin : Write
    if (rst_p) begin
      for (int i = 0; i < 32; i++) begin
        nexthop_table_entries[i].nexthop <= 128'h0;
        nexthop_table_entries[i].iface   <= 2'b00;
      end
    end else if (wea_p) begin
      nexthop_table_entries[w_addr].nexthop <= w_nexthop;
      nexthop_table_entries[w_addr].iface   <= w_iface;
    end
  end

endmodule
