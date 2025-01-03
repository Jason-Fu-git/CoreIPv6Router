`timescale 1ns / 1ps

`include "frame_datapath.vh"

// Priority : rip > ns > nud > fw
module out_arbiter (
    input wire clk,
    input wire rst_p,

    // input beat
    input frame_beat in_ns,
    input frame_beat in_fw,
    input frame_beat in_nud,
    input frame_beat in_rip,

    // input valid
    input wire ns_valid,
    input wire fw_valid,
    input wire nud_valid,
    input wire rip_valid,

    // out ready
    output reg ns_ready,
    output reg fw_ready,
    output reg nud_ready,
    output reg rip_ready,

    output reg out_valid,
    input wire out_ready,
    output frame_beat out,

    // DEBUG signals
    output reg handling_ns_delay,
    output reg handling_fw_delay,
    output reg handling_nud_delay,
    output reg handling_rip_delay
);

  reg  handling_ns;
  reg  handling_fw;
  reg  handling_nud;
  reg  handling_rip;

  wire idle;

  assign idle = (!handling_ns  || (out_ready && ns_valid  && in_ns.last ))
               && (!handling_fw  || (out_ready && fw_valid  && in_fw.last ))
               && (!handling_nud || (out_ready && nud_valid && in_nud.last))
               && (!handling_rip || (out_ready && rip_valid && in_rip.last));

  assign rip_ready = idle ? (out_ready) : (handling_rip && out_ready);
  assign ns_ready = idle ? (out_ready && !rip_valid) : (handling_ns && out_ready);
  assign nud_ready = idle ? (out_ready && !rip_valid && !ns_valid) : (handling_nud && out_ready);
  assign fw_ready = idle ? (out_ready && !rip_valid && !ns_valid && !nud_valid) : (handling_fw && out_ready);


  always_ff @(posedge clk) begin
    if (rst_p) begin
      handling_ns  <= 0;
      handling_fw  <= 0;
      handling_nud <= 0;
      handling_rip <= 0;
    end else begin
      if (idle) begin
        if (rip_valid && in_rip.is_first) begin
          handling_rip <= 1;
        end else if (!handling_rip && ns_valid && in_ns.is_first) begin
          handling_ns <= 1;
        end else if (!handling_rip && !handling_ns && nud_valid && in_nud.is_first) begin
          handling_nud <= 1;
        end else if (!handling_rip && !handling_ns && !handling_nud && fw_valid && in_fw.is_first) begin
          handling_fw <= 1;
        end
      end
      if (handling_rip && rip_valid && in_rip.last && out_ready) begin
        handling_rip <= 0;
      end else if (handling_ns && ns_valid && in_ns.last && out_ready) begin
        handling_ns <= 0;
      end else if (handling_nud && nud_valid && in_nud.last && out_ready) begin
        handling_nud <= 0;
      end else if (handling_fw && fw_valid && in_fw.last && out_ready) begin
        handling_fw <= 0;
      end
    end
  end

  logic handling_rip_comb;
  assign handling_rip_comb = handling_rip || (rip_valid && in_rip.is_first);

  always_comb begin
    out = handling_rip ? in_rip :
             (handling_ns ? in_ns :
             (handling_nud ? in_nud :
             (handling_fw ? in_fw :
             (rip_valid ? in_rip :
             (ns_valid ? in_ns :
             (nud_valid ? in_nud :
             (fw_valid ? in_fw : 0)))))));
    out.valid = ( ((handling_rip_comb) && rip_valid)
                 || ( (!handling_rip_comb)
                    && (handling_ns || in_ns.is_first) && ns_valid)
                 || ( (!handling_rip_comb && !handling_ns && !in_ns.is_first)
                    &&(handling_nud || in_nud.is_first) && nud_valid)
                 || ( (!handling_rip_comb && !handling_ns && !in_ns.is_first && !handling_nud && !in_nud.is_first)
                    && (handling_fw || in_fw.is_first) && fw_valid));
    out_valid = out.valid;
  end


  // DEBUG signals
  always_ff @(posedge clk) begin
    if (rst_p) begin
      handling_ns_delay  <= 0;
      handling_fw_delay  <= 0;
      handling_nud_delay <= 0;
      handling_rip_delay <= 0;
    end else begin
      handling_ns_delay  <= handling_ns;
      handling_fw_delay  <= handling_fw;
      handling_nud_delay <= handling_nud;
      handling_rip_delay <= handling_rip;
    end
  end

endmodule
