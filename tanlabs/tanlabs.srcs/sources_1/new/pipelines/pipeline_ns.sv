`timescale 1ns / 1ps

`include "frame_datapath.vh"

// valid_i is in_valid
// ready_i is out_ready
// valid_o is out_valid
// ready_o is in_ready

module pipeline_ns (
  input  wire         clk,
  input  wire         rst_p,

  input  wire         valid_i,  // Last pipeline valid
  input  wire         ready_i,  // Next pipeline ready
  output reg          valid_o,  // To the next pipeline
  output reg          ready_o,  // To the last pipeline

  input  frame_beat   in,
  output frame_beat   out,

  input  wire         cache_ready,
  output reg          cache_wea_p,
  output cache_entry  cache_out,

  input  wire [3:0] [ 47:0] mac_addrs,   // router MAC address
  input  wire [3:0] [127:0] ipv6_addrs   // router IPv6 address
);

  frame_beat       first_beat;  // The first pack, containing Ether/Ipv6 headers
  ether_hdr        in_ether_hdr;  // Ether header of the packet being handled now
  ip6_hdr          in_ip6_hdr;  // IPv6 header of the packet being handled now
  logic      [1:0] in_meta_src;  // Interface

  assign in_ether_hdr = first_beat.data;
  assign in_ip6_hdr   = first_beat.data.ip6;
  assign in_meta_src  = first_beat.meta.id;

  typedef enum logic [3:0] {
    NS_IDLE,
    NS_WAIT,
    NS_CHECK_NS,
    NS_SEND_1,
    NS_CHECK_NA,
    NS_SEND_2
  } ns_state_t;

  ns_state_t ns_state, ns_next_state;

  NS_packet ns_packet;  // NS packet stored from input
  NA_packet na_packet;  // Here checksum is set to 0; do not send this directly

  always_comb begin
    cache_out.ip6_addr = ns_packet.ether.ip6.src;
    cache_out.mac_addr = ns_packet.option.mac_addr;
    cache_out.iface    = in_meta_src;
  end

  reg cache_writing;

  logic [15:0] ns_checksum;
  logic [15:0] na_checksum;
  logic [15:0] na_checksum_reg;

  logic ns_checksum_valid;
  logic na_checksum_valid;
  logic ns_checksum_ea;
  logic na_checksum_ea;
  logic ns_checksum_ok;

  logic ns_legal;

  assign ns_legal = (
    (ns_packet.option.len > 0)
   && (ns_packet.icmpv6.target_addr[7:0] != 8'hff)
   && (ns_checksum_ok)
   && (ipv6_addrs[in_meta_src] == ns_packet.icmpv6.target_addr));

  always_comb begin
    case (ns_state)
      NS_IDLE     : ns_next_state = ((valid_i          ) ? NS_WAIT     : NS_IDLE    );
      NS_WAIT     : ns_next_state = ((valid_i          ) ? NS_CHECK_NS : NS_WAIT    );
      NS_CHECK_NS : ns_next_state = ((ns_checksum_valid) ? NS_SEND_1   : NS_CHECK_NS);
      NS_SEND_1   : ns_next_state = ((ready_i          ) ? NS_CHECK_NA : NS_SEND_1  );
      NS_CHECK_NA : ns_next_state = ((na_checksum_valid) ? NS_SEND_2   : NS_CHECK_NA);
      NS_SEND_2   : ns_next_state = ((ready_i          ) ? NS_IDLE     : NS_SEND_2  );
      default     : ns_next_state = NS_IDLE;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst_p) begin
      ns_state <= NS_IDLE;
    end else begin
      ns_state <= ns_next_state;
    end
  end

  always_ff @(posedge clk) begin
    if (rst_p) begin
      first_beat <= 0;
      out <= 0;
      ns_packet <= 0;
      ns_checksum_ea <= 0;
      ns_checksum_ok <= 0;
      na_checksum_reg <= 0;
      na_checksum_ea <= 0;
      cache_wea_p <= 0;
      cache_writing <= 0;
    end else begin
      if (ns_checksum_valid) begin
        ns_checksum_ok <= (ns_checksum == 16'hffff);
      end
      if          ((ns_state == NS_IDLE) && (valid_i)) begin
        first_beat <= in;
      end else if ((ns_state == NS_WAIT) && (valid_i)) begin
        ns_packet <= {in.data, first_beat.data};
        ns_checksum_ea <= 1'b1;
        na_checksum_ea <= 1'b1;
      end else if ((ns_state == NS_SEND_1) && (ready_i)) begin
        ns_checksum_ea <= 0;
        ns_checksum_ok <= 0;
        cache_writing <= 0;
      end else if ((ns_state == NS_SEND_2) && (ready_i)) begin
        na_checksum_ea <= 0;
      end
      if (ns_state == NS_WAIT) begin
        out.data            <= na_packet[447:0];  // 56 bytes
        out.is_first        <= 1'b1;
        out.last            <= 1'b0;  // Not the last pack
        out.valid           <= 1'b0;  // Wait for ND_SEND_1 to send
        out.keep            <= 56'hffffffffffffff;  // Full pack
        out.meta.dont_touch <= 1'b0;
        out.meta.drop_next  <= 1'b0;
        out.meta.dest       <= in_meta_src;
      end else if (ns_state == NS_SEND_1) begin
        out.valid <= 1;
        out.meta.drop <= !ns_legal;
        if (ns_legal && !cache_writing) begin
          cache_wea_p <= 1'b1;
          cache_writing <= 1'b1;
        end else if (ns_legal && cache_writing) begin
          cache_wea_p <= 1'b0;
        end
      end else if (ns_state == NS_SEND_2) begin
        out.data <= {208'h0, na_packet[687:448]};  // 86 - 56 = 30 bytes
        out.data[15:0] <= ~{na_checksum[7:0], na_checksum[15:8]};
        out.is_first <= 1'b0;
        out.last <= 1'b1;  // The last pack
        out.valid <= 1'b1;  // Send directly
        out.keep            <= 56'h0000003fffffff;                // 30 bytes valid: 0b...11_1111_1111_1111_1111_1111_1111_1111
        out.meta.drop <= 1'b0;
        out.meta.dont_touch <= 1'b0;
        out.meta.drop_next <= 1'b0;
        out.meta.dest <= in_meta_src;
      end else begin
        out.valid <= 0;
      end
    end
  end

  always_comb begin
    na_packet.option.option_type    = 8'd2;
    na_packet.option.len            = 8'd1;
    na_packet.icmpv6.icmpv6_type    = ICMPv6_HDR_TYPE_NA;  // 8'd136
    na_packet.icmpv6.code           = 8'd0;
    na_packet.icmpv6.checksum       = 16'd0;
    na_packet.icmpv6.R              = 1'b1;  // sent from router
    na_packet.icmpv6.S              = 1'b1;  // TODO: set the flag, now is default: sent as response to NS
    na_packet.icmpv6.O              = 1'b0;  // TODO: set the flag
    na_packet.icmpv6.reserved_lo    = 24'h0;
    na_packet.icmpv6.reserved_hi    = 5'h0;
    na_packet.icmpv6.target_addr    = in_ip6_hdr.src;
    na_packet.ether.dst             = in_ether_hdr.src;
    na_packet.ether.ethertype       = 16'hdd86;  // IPv6
    na_packet.ether.ip6.dst         = in_ip6_hdr.src;
    na_packet.ether.ip6.next_hdr    = IP6_HDR_TYPE_ICMPv6;  // 8'd58
    na_packet.ether.ip6.hop_limit   = IP6_HDR_HOP_LIMIT_DEFAULT;  // 8'd255
    na_packet.ether.ip6.payload_len = {
      32, 8'd0
    };  // 24 bytes for ICMPv6 header, 8 bytes for option
    na_packet.ether.ip6.flow_lo     = 24'b0;
    na_packet.ether.ip6.flow_hi     = 4'b0;
    na_packet.ether.ip6.version     = 4'd6;
    na_packet.option.mac_addr       = mac_addrs[in_meta_src];
    na_packet.ether.src             = mac_addrs[in_meta_src];
    na_packet.ether.ip6.src         = ipv6_addrs[in_meta_src];
  end

  // assign valid_o        = ((ns_state == NS_SEND_1) || (ns_state == NS_SEND_2));
  assign valid_o = out.valid;
  assign ready_o        = ((ns_state == NS_IDLE  ) || (ns_state == NS_WAIT  ));

  checksum_calculator checksum_calculator_ns (
    .clk            (clk),
    .rst_p          (rst_p),
    .ip6_src        (ns_packet.ether.ip6.src),
    .ip6_dst        (ns_packet.ether.ip6.dst),
    .payload_length ({16'd0, ns_packet.ether.ip6.payload_len}),
    .next_header    (ns_packet.ether.ip6.next_hdr),
    .current_payload({ns_packet.option, ns_packet.icmpv6}),
    .mask           (~(256'd0)),
    .is_first       (1'b1),
    .ea_p           (ns_checksum_ea),
    .checksum       (ns_checksum),
    .valid          (ns_checksum_valid)
  );

  checksum_calculator checksum_calculator_ns_na (
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

endmodule : pipeline_ns
