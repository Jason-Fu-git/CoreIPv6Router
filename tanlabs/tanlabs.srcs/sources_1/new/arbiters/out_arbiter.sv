`timescale 1ns / 1ps

`include "frame_datapath.vh"


module out_arbiter (
    input wire clk,
    input wire rst_p,
    input frame_beat in_ns,
    input frame_beat in_fw,
    input frame_beat in_nud,
    input wire ns_valid,
    input wire fw_valid,
    input wire nud_valid,
    input wire out_ready,
    output frame_beat out,
    output reg out_valid,
    output reg ns_ready,
    output reg fw_ready,
    output reg nud_ready
);

  reg  handling_ns;
  reg  handling_fw;
  reg  handling_nud;

  wire idle;

  assign idle = (!handling_ns  || (out_ready && ns_valid  && in_ns.last ))
               && (!handling_fw  || (out_ready && fw_valid  && in_fw.last ))
               && (!handling_nud || (out_ready && nud_valid && in_nud.last));

  assign ns_ready = idle ? (out_ready) : (handling_ns && out_ready);
  assign nud_ready = idle ? (out_ready && !ns_valid) : (handling_nud && out_ready);
  assign fw_ready = idle ? (out_ready && !ns_valid && !nud_valid) : (handling_fw && out_ready);

  always_ff @(posedge clk) begin
    if (rst_p) begin
      handling_ns  <= 0;
      handling_fw  <= 0;
      handling_nud <= 0;
    end else begin
      if (ns_valid && in_ns.is_first) begin
        handling_ns <= 1;
      end else if (nud_valid && in_nud.is_first) begin
        handling_nud <= 1;
      end else if (fw_valid && in_fw.is_first) begin
        handling_fw <= 1;
      end
      if (handling_ns && ns_valid && in_ns.last && out_ready) begin
        handling_ns <= 0;
      end else if (handling_nud && nud_valid && in_nud.last && out_ready) begin
        handling_nud <= 0;
      end else if (handling_fw && fw_valid && in_fw.last && out_ready) begin
        handling_fw <= 0;
      end
    end
  end

  always_comb begin
    out = handling_ns ? in_ns :
             (handling_nud ? in_nud :
             (handling_fw ? in_fw :
             (ns_valid ? in_ns :
             (nud_valid ? in_nud :
             (fw_valid ? in_fw : 0)))));
    out.valid = ((handling_ns || in_ns.is_first) && ns_valid)
                 || ((handling_nud || in_nud.is_first) && nud_valid)
                 || ((handling_fw || in_fw.is_first) && fw_valid);
    out_valid = out.valid;
  end

endmodule
