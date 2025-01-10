`timescale 1ns / 1ps

`include "frame_datapath.vh"

// valid_i is in_valid
// ready_i is out_ready
// valid_o is out_valid
// ready_o is in_ready

module pipeline_nud (
    input  wire               clk,
    input  wire               rst_p,
    input  wire               we_i,        // needed to send NS, trigger
    input  wire       [127:0] tgt_addr_i,  // target address
    input  wire       [127:0] ip6_addr_i,  // self IPv6 address
    input  wire       [ 47:0] mac_addr_i,  // self MAC address
    input  wire       [  1:0] iface_i,     // interface ID (0, 1, 2, 3)
    input  wire               ready_i,     // out can be sent
    output frame_beat         out,
    output reg                valid_o,
    output reg                ready_o
);

  NS_packet        NS_o;  // NS packet to be sent by datapath
  logic     [15:0] checksum_o;  // checksum of NS packet
  logic            checksum_ea;
  logic            checksum_valid;

  typedef enum logic [3:0] {
    NUD_IDLE,
    NUD_CHECK,
    NUD_SEND_1,
    NUD_WAIT,
    NUD_SEND_2
  } nud_state_t;

  nud_state_t nud_state, nud_next_state;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      nud_state <= NUD_IDLE;
    end else begin
      nud_state <= nud_next_state;
    end
  end

  logic [127:0] sn_addr;  // solicited-node address
  logic [127:0] tgt_addr;
  logic [127:0] ip6_addr;
  logic [ 47:0] mac_addr;
  logic [  1:0] iface;

  always_comb begin
    sn_addr[103:0] = {104'h010000000000000000000002ff};
  end

  always_ff @(posedge clk) begin
    if (rst_p) begin
      out <= 0;
      valid_o <= 0;
      sn_addr[127:104] <= 24'b0;
      tgt_addr <= 128'b0;
      ip6_addr <= 128'b0;
      mac_addr <= 48'b0;
      iface <= 2'b0;
      checksum_ea <= 1'b0;
    end else begin
      if ((nud_state == NUD_IDLE) && we_i) begin
        sn_addr[127:104] <= tgt_addr_i[127:104];
        tgt_addr <= tgt_addr_i;
        ip6_addr <= ip6_addr_i;
        mac_addr <= mac_addr_i;
        iface <= iface_i;
        checksum_ea <= 1'b1;
      end else if ((nud_state == NUD_SEND_2) && ready_i) begin
        checksum_ea <= 1'b0;
      end
      if (nud_state == NUD_SEND_1) begin
        out.data <= NS_o[447:0];
        out.is_first <= 1'b1;
        out.last <= 1'b0;
        out.valid <= 1'b1;
        out.keep <= 56'hffffffffffffff;
        out.meta.drop <= 1'b0;
        out.meta.dont_touch <= 1'b0;
        out.meta.drop_next <= 1'b0;
        out.meta.dest <= iface;
        valid_o <= 1;
      end else if (nud_state == NUD_SEND_2) begin
        out.data            <= {208'h0, NS_o[687:448]};
        out.data[15:0]      <= ~{checksum_o[7:0], checksum_o[15:8]};
        out.is_first        <= 1'b0;
        out.last            <= 1'b1;
        out.valid           <= 1'b1;
        out.keep            <= 56'h0000003fffffff;
        out.meta.drop       <= 1'b0;
        out.meta.dont_touch <= 1'b0;
        out.meta.drop_next  <= 1'b0;
        out.meta.dest       <= iface;
        valid_o <= 1;
      end else begin
        out.valid <= 1'b0;
        valid_o <= 0;
      end
    end
  end

  always_comb begin
    NS_o.ether.ip6.dst = tgt_addr;
    NS_o.ether.ip6.src = ip6_addr;
    NS_o.ether.ip6.hop_limit = 255;
    NS_o.ether.ip6.next_hdr = IP6_HDR_TYPE_ICMPv6;
    NS_o.ether.ip6.payload_len = {8'd32, 8'd0};
    NS_o.ether.ip6.flow_lo = 24'b0;
    NS_o.ether.ip6.flow_hi = 4'b0;
    NS_o.ether.ip6.version = 4'd6;
    NS_o.ether.ethertype = 16'hdd86;  // IPv6
    NS_o.ether.src = mac_addr;
    NS_o.ether.dst = {sn_addr[127:96], 16'h3333};
    NS_o.option.mac_addr = mac_addr;
    NS_o.option.len = 8'd1;
    NS_o.option.option_type = 8'd1;
    NS_o.icmpv6.target_addr = tgt_addr;
    NS_o.icmpv6.reserved_lo = 24'b0;
    NS_o.icmpv6.R = 1'b0;
    NS_o.icmpv6.S = 1'b0;
    NS_o.icmpv6.O = 1'b0;
    NS_o.icmpv6.reserved_hi = 5'b0;
    NS_o.icmpv6.code = 8'd0;
    NS_o.icmpv6.icmpv6_type = ICMPv6_HDR_TYPE_NS;
    NS_o.icmpv6.checksum = 16'b0;
  end

  always_comb begin
    case (nud_state)
      NUD_IDLE: nud_next_state = we_i ? NUD_CHECK : NUD_IDLE;
      NUD_CHECK: nud_next_state = checksum_valid ? NUD_SEND_1 : NUD_CHECK;
      NUD_SEND_1: nud_next_state = ready_i ? NUD_WAIT : NUD_SEND_1;
      NUD_WAIT: nud_next_state = NUD_SEND_2;
      NUD_SEND_2: nud_next_state = ready_i ? NUD_IDLE : NUD_SEND_2;
      default: nud_next_state = NUD_IDLE;
    endcase
  end

  checksum_calculator checksum_calculator_NUD (
      .clk(clk),
      .rst_p(rst_p),
      .ip6_src(NS_o.ether.ip6.src),
      .ip6_dst(NS_o.ether.ip6.dst),
      .payload_length({16'd0, NS_o.ether.ip6.payload_len}),
      .next_header(NS_o.ether.ip6.next_hdr),
      .current_payload({NS_o.option, NS_o.icmpv6}),
      .mask(~(256'h0)),
      .is_first(1'b1),
      .ea_p(checksum_ea),
      .checksum(checksum_o),
      .valid(checksum_valid)
  );

  // assign valid_o = (nud_state == NUD_SEND_1) || (nud_state == NUD_SEND_2);

  assign ready_o = (nud_state == NUD_IDLE) || ((nud_state == NUD_SEND_2) && ready_i);

endmodule

