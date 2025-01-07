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

  typedef enum logic [2:0] {
    OUT_ARBITER_IDLE,
    OUT_ARBITER_NS,
    OUT_ARBITER_FW,
    OUT_ARBITER_NUD,
    OUT_ARBITER_RIP
  } out_arbiter_state_t;
  out_arbiter_state_t state, next_state;

  logic handling_rip;
  logic handling_ns;
  logic handling_nud;
  logic handling_fw;

  always_comb begin : NEXT_STATE
    next_state = state;
    case (state)
      OUT_ARBITER_IDLE:
      if (rip_valid && in_rip.is_first) begin
        next_state = OUT_ARBITER_RIP;
      end else if (ns_valid && in_ns.is_first) begin
        next_state = OUT_ARBITER_NS;
      end else if (nud_valid && in_nud.is_first) begin
        next_state = OUT_ARBITER_NUD;
      end else if (fw_valid && in_fw.is_first) begin
        next_state = OUT_ARBITER_FW;
      end
      OUT_ARBITER_RIP:
      if (rip_valid && in_rip.last && out_ready) begin
        next_state = OUT_ARBITER_IDLE;
      end else begin
        next_state = OUT_ARBITER_RIP;
      end
      OUT_ARBITER_NS:
      if (ns_valid && in_ns.last && out_ready) begin
        next_state = OUT_ARBITER_IDLE;
      end else begin
        next_state = OUT_ARBITER_NS;
      end
      OUT_ARBITER_NUD:
      if (nud_valid && in_nud.last && out_ready) begin
        next_state = OUT_ARBITER_IDLE;
      end else begin
        next_state = OUT_ARBITER_NUD;
      end
      OUT_ARBITER_FW:
      if (fw_valid && in_fw.last && out_ready) begin
        next_state = OUT_ARBITER_IDLE;
      end else begin
        next_state = OUT_ARBITER_FW;
      end
      default: next_state = OUT_ARBITER_IDLE;
    endcase
  end


  always_ff @(posedge clk) begin : STATE_UPDATE
    if (rst_p) begin
      state <= OUT_ARBITER_IDLE;
    end else begin
      state <= next_state;
    end
  end


  always_comb begin : STATE_MACHINE
    rip_ready    = 0;
    ns_ready     = 0;
    nud_ready    = 0;
    fw_ready     = 0;
    handling_fw  = 0;
    handling_ns  = 0;
    handling_nud = 0;
    handling_rip = 0;
    out          = 0;
    case (state)
      OUT_ARBITER_IDLE: begin
        rip_ready = out_ready;
        ns_ready  = out_ready && !rip_valid;
        nud_ready = out_ready && !rip_valid && !ns_valid;
        fw_ready  = out_ready && !rip_valid && !ns_valid && !nud_valid;
        if (rip_valid) begin
          out          = in_rip;
          handling_rip = 1;
        end else if (ns_valid) begin
          out         = in_ns;
          handling_ns = 1;
        end else if (nud_valid) begin
          out          = in_nud;
          handling_nud = 1;
        end else if (fw_valid) begin
          out         = in_fw;
          handling_fw = 1;
        end else begin
          out = 0;
        end
      end
      OUT_ARBITER_NS: begin
        ns_ready    = out_ready;
        out         = in_ns;
        handling_ns = 1;
      end
      OUT_ARBITER_FW: begin
        fw_ready    = out_ready;
        out         = in_fw;
        handling_fw = 1;
      end
      OUT_ARBITER_NUD: begin
        nud_ready    = out_ready;
        out          = in_nud;
        handling_nud = 1;
      end
      OUT_ARBITER_RIP: begin
        rip_ready    = out_ready;
        out          = in_rip;
        handling_rip = 1;
      end
      default: begin

      end
    endcase
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
