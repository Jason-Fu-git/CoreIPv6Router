`timescale 1ns / 1ps

`include "frame_datapath.vh"

module in_arbiter (
    input wire clk,
    input wire rst_p,

    // in beat
    input frame_beat in,
    input wire in_valid,

    // out beats
    output frame_beat out_ns,
    output frame_beat out_na,
    output frame_beat out_fw,
    output frame_beat out_rip,

    // out valid signals
    output reg ns_valid,
    output reg na_valid,
    output reg fw_valid,
    output reg rip_valid,

    // in ready signal
    output reg in_ready,

    // out ready signals
    input wire ns_ready,
    input wire na_ready,
    input wire fw_ready,
    input wire rip_ready
);

  frame_beat in_reg;

  reg handling_ns;
  reg handling_na;
  reg handling_fw;
  reg handling_rip;

  wire first_ns;
  wire first_na;
  wire first_fw;
  wire first_rip;

  assign first_ns = (in.data.ip6.next_hdr          == IP6_HDR_TYPE_ICMPv6                     )
                   && (in.data.ip6.p[7:0]            == ICMPv6_HDR_TYPE_NS                    )
                   && (in.data.ip6.hop_limit         == IP6_HDR_HOP_LIMIT_DEFAULT             )
                   && (in.data.ip6.p[15:8]           == 0                                     )
                   && ({in.data.ip6.payload_len[7:0], in.data.ip6.payload_len[15:8]} >= 16'd24)
                   && (in.data.ip6.payload_len[10:8] == 3'b000                                )
                   && (in.data.ip6.src               != 0                                     );

  assign first_na = (in.data.ip6.next_hdr          == IP6_HDR_TYPE_ICMPv6                     )
                   && (in.data.ip6.p[7:0]            == ICMPv6_HDR_TYPE_NA                    )
                   && (in.data.ip6.hop_limit         == IP6_HDR_HOP_LIMIT_DEFAULT             )
                   && (in.data.ip6.p[15:8]           == 0                                     )
                   && ({in.data.ip6.payload_len[7:0], in.data.ip6.payload_len[15:8]} >= 16'd24)
                   && (in.data.ip6.payload_len[10:8] == 3'b000                                )
                   && (in.data.ip6.src               != 0                                     );

  assign first_rip = (in.data.ip6.next_hdr == IP6_HDR_TYPE_UDP                     )
                     && (in.data.ip6.version == 6                                 )
                     && ({in.data.ip6.p[7:0], in.data.ip6.p[15:8]} == UDP_PORT_RIP);


  assign first_fw = (in.data.ip6.version == 6) && (in.data.ip6.hop_limit > 1);


  assign in_ready = !(
                        (handling_ns && !ns_ready)
                        || (handling_na && !na_ready)
                        || (handling_fw && !fw_ready)
                        || (handling_rip && !rip_ready)
                    );

  always_ff @(posedge clk) begin
    if (rst_p) begin
      in_reg <= 0;
      handling_ns  <= 0;
      handling_na  <= 0;
      handling_fw  <= 0;
      handling_rip <= 0;
      ns_valid     <= 0;
      na_valid     <= 0;
      fw_valid     <= 0;
      rip_valid    <= 0;
    end else begin
      if (in_valid && in_ready) begin
        in_reg <= in;
        if (in.is_first) begin
          if (first_ns) begin
            handling_ns  <= 1;
            handling_na  <= 0;
            handling_fw  <= 0;
            handling_rip <= 0;
            ns_valid     <= 1;
            na_valid     <= 0;
            fw_valid     <= 0;
            rip_valid    <= 0;
          end else if (first_na) begin
            handling_ns  <= 0;
            handling_na  <= 1;
            handling_fw  <= 0;
            handling_rip <= 0;
            ns_valid     <= 0;
            na_valid     <= 1;
            fw_valid     <= 0;
            rip_valid    <= 0;
          end else if(first_rip) begin
            handling_ns  <= 0;
            handling_na  <= 0;
            handling_fw  <= 0;
            handling_rip <= 1;
            ns_valid     <= 0;
            na_valid     <= 0;
            fw_valid     <= 0;
            rip_valid    <= 1;
          end else if (first_fw) begin
            handling_ns  <= 0;
            handling_na  <= 0;
            handling_fw  <= 1;
            handling_rip <= 0;
            ns_valid     <= 0;
            na_valid     <= 0;
            fw_valid     <= 1;
          end else begin
            handling_ns  <= 0;
            handling_na  <= 0;
            handling_fw  <= 0;
            handling_rip <= 0;
            ns_valid     <= 0;
            na_valid     <= 0;
            fw_valid     <= 0;
            rip_valid    <= 0;
          end
        end else begin
          if (handling_ns) begin
            ns_valid  <= 1;
            na_valid  <= 0;
            fw_valid  <= 0;
            rip_valid <= 0;
          end else if (handling_na) begin
            ns_valid  <= 0;
            na_valid  <= 1;
            fw_valid  <= 0;
            rip_valid <= 0;
          end else if (handling_rip) begin
            ns_valid  <= 0;
            na_valid  <= 0;
            fw_valid  <= 0;
            rip_valid <= 1;
          end else if (handling_fw) begin
            ns_valid  <= 0;
            na_valid  <= 0;
            fw_valid  <= 1;
            rip_valid <= 0;
          end else begin
            ns_valid  <= 0;
            na_valid  <= 0;
            fw_valid  <= 0;
            rip_valid <= 0;
          end
        end
      end else begin
        if (handling_ns && ns_ready) begin
          ns_valid <= 0;
        end else if (handling_na && na_ready) begin
          na_valid <= 0;
        end else if (handling_rip && rip_ready) begin
          rip_valid <= 0;
        end else if (handling_fw && fw_ready) begin
          fw_valid <= 0;
        end
      end
    end
  end

  assign out_ns  = ns_valid ? in_reg : 0;
  assign out_na  = na_valid ? in_reg : 0;
  assign out_fw  = fw_valid ? in_reg : 0;
  assign out_rip = rip_valid ? in_reg : 0;

endmodule
