`timescale 1ns / 1ps

`include "frame_datapath.vh"

// valid_i is in_valid
// ready_i is out_ready
// valid_o is out_valid
// ready_o is in_ready

module pipeline_na (
    input wire clk,
    input wire rst_p,

    input  wire valid_i,  // Last pipeline valid
    input  wire ready_i,  // Cache ready
    output reg  ready_o,  // To the last pipeline
    output reg  valid_o,  // Write cache valid

    input  frame_beat  in,
    output cache_entry out
);

  frame_beat       first_beat;  // The first pack, containing Ether/Ipv6 headers
  ether_hdr        in_ether_hdr;  // Ether header of the packet being handled now
  ip6_hdr          in_ip6_hdr;  // IPv6 header of the packet being handled now
  logic      [1:0] in_meta_src;  // Interface

  assign in_ether_hdr = first_beat.data;
  assign in_ip6_hdr   = first_beat.data.ip6;
  assign in_meta_src  = first_beat.meta.id;

  NA_packet na_packet;
  logic [15:0] na_checksum;
  logic na_checksum_ea;
  logic na_checksum_ok;
  logic na_checksum_valid;
  logic na_valid;

  assign na_valid = ((na_packet.option.len > 0) && (na_checksum_ok));

  typedef enum logic [3:0] {
    NA_IDLE,   // Wait for an NA pack
    NA_WAIT,   // Wait for the second pack to arrive
    NA_CHECK,  // Wait for NA checksum
    NA_CACHE   // Write ND cache
  } na_state_t;

  na_state_t na_state, na_next_state;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      na_state <= NA_IDLE;
    end else begin
      na_state <= na_next_state;
    end
  end

  always_ff @(posedge clk) begin
    if (rst_p) begin
      out <= 0;
      first_beat <= 0;
      na_packet <= 0;
      na_checksum_ea <= 0;
      na_checksum_ok <= 0;
    end else begin
      if (na_checksum_valid) begin
        na_checksum_ok <= (na_checksum == 16'hffff);
      end
      if ((na_state == NA_IDLE) && valid_i) begin
        first_beat <= in;
      end else if ((na_state == NA_WAIT) && valid_i) begin
        na_packet      <= {in.data, first_beat.data};
        na_checksum_ea <= 1'b1;
      end else if ((na_state == NA_CHECK) && na_checksum_valid) begin
        na_checksum_ea <= 1'b0;
        out.ip6_addr <= na_packet.ether.ip6.src;
        out.mac_addr <= na_packet.option.mac_addr;
        out.iface    <= in_meta_src;
      end else if (na_next_state == NA_IDLE) begin
        na_checksum_ok <= 1'b0;
      end
    end
  end

  always_comb begin
    case (na_state)
      NA_IDLE: begin
        na_next_state = (valid_i) ? NA_WAIT : NA_IDLE;
      end
      NA_WAIT: begin
        na_next_state = (valid_i) ? NA_CHECK : NA_WAIT;
      end
      NA_CHECK: begin
        na_next_state = (na_checksum_valid) ? ((na_checksum == 16'hffff) ? NA_CACHE : NA_IDLE) : NA_CHECK;
      end
      NA_CACHE: begin
        na_next_state = (ready_i) ? NA_IDLE : NA_CACHE;
      end
      default: begin
        na_next_state = NA_IDLE;
      end
    endcase
  end

  assign valid_o = (na_state == NA_CACHE);
  assign ready_o = ((na_state == NA_IDLE) || (na_state == NA_WAIT));


  checksum_calculator checksum_calculator_na (
      .clk            (clk),
      .rst_p          (rst_p),
      .ip6_src        (na_packet.ether.ip6.src),
      .ip6_dst        (na_packet.ether.ip6.dst),
      .payload_length ({16'd0, na_packet.ether.ip6.payload_len}),
      .next_header    (na_packet.ether.ip6.next_hdr),
      .current_payload({na_packet.option, na_packet.icmpv6}),
      .mask           (~(256'd0)),
      .is_first       (1'b1),
      .ea_p           (na_checksum_ea),
      .checksum       (na_checksum),
      .valid          (na_checksum_valid)
  );

endmodule : pipeline_na
