`timescale 1ns / 1ps
/**
 * Implementation of checksum calculator for IPv6 packets.
 *
 * This module is implemented in combinational logic. The calculation is done within one cycle.
 * The returned checksum is not bit-wise inverted. And it is the checksum value for the current beat.
 * If the packets are across multiple beats, the checksum should be accumulated externally.
 *
 * Internet stream should be bitwise flipped. For example, if the input stream is
 *
 * 0  1   2  3   4
 * + ---- + ---- +
 * | 0x12 | 0x34 |
 * + ---- + ---- +
 *
 * The input should be
 *
 * 4  3   2  1   0
 * + ---- + ---- +
 * | 0x12 | 0x34 |
 * + ---- + ---- +
 *
 *
 *  Usage:
 *  (1) For the first beat of the frame, set is_first to 1.
 *  ip6_src, ip6_dst, payload_length, next_header should be set to the corresponding values.
 *  If the first beat contains payload, set current_payload_length to the length of the part
 *  of the payload in this beat and set current_payload to that part.
 *
 *  (2) For the following beats, set is_first to 0.
 *  Set current_payload_length to the length of the payload in this beat
 *  and set current_payload to that part.
 *
 *  (3) All the signals should be hold at least for one cycle.
 *  After you saved the checksum, you can reset the signals.
 *
 *  @author Jason Fu
 *
 */
localparam PAYLOAD_LENGTH = 8 * 32;
module checksum_calculator (
    input wire clk,
    input wire rst_p,

    // pesudo header
    input wire [127:0] ip6_src,  // 16-byte source address, e.g. fe80::1
    input wire [127:0] ip6_dst,  // 16-byte destination address
    input wire [31:0] payload_length,  // 4-byte payload length **in octets**
    input wire [7:0] next_header,  // 1-byte next header

    // current payload (Should not include the IPv6 header)
    input wire [PAYLOAD_LENGTH-1:0] current_payload,  // BEAT_WIDTH-bit payload
    input wire [PAYLOAD_LENGTH-1:0] mask,  // mask for the payload, 1 means the bit is considered

    // control signals
    input wire is_first,  // whether this is the first beat of the frame
    input wire ea_p,  // enable signal

    // output
    output reg [15:0] checksum,  // current step checksum value (not bit-wise inverted)
    output reg valid  // valid signal;
);
  logic [575:0] data;
  logic [575:0] unflipped_data;

  always_comb begin : DataConcat
    if (is_first) begin
      unflipped_data = {ip6_src, ip6_dst, payload_length, next_header, 24'b0, current_payload & mask};
    end else begin
      unflipped_data = {320'd0, current_payload & mask};
    end
  end

  bytewise_flipper #(.BEAT_WIDTH(576)) data_flipper(
    .data_in(unflipped_data),
    .data_out(data)
  );

  // Checksum calculation
  logic [17:0][16:0] checksum_tmp;
  reg   [17:0][16:0] data_a;
  reg   [17:0][16:0] data_b;

  always_comb begin : Calc
    for (int i = 0; i < 18; i++) begin
      checksum_tmp[i] = data_a[i] + data_b[i];
      if (checksum_tmp[i][16]) begin
        checksum_tmp[i][15:0] = checksum_tmp[i][15:0] + 1;
        checksum_tmp[i][16]   = 0;
      end
    end
  end

  assign checksum = checksum_tmp[0][15:0];

  // Controller
  reg [2:0] stage;
  always_ff @(posedge clk) begin : Controller
    if (rst_p) begin
      stage <= 0;
      valid <= 0;
      for (int i = 0; i < 18; i++) begin
        data_a[i] <= 0;
        data_b[i] <= 0;
      end
    end else begin
      if (ea_p) begin
        if (!valid) begin
          case (stage)
            3'd0: begin
              for (int i = 0; i < 18; i++) begin
                data_a[i] <= data[i*32+:16];
                data_b[i] <= data[i*32+16+:16];
              end
              stage <= 3'd1;
              valid <= 0;
            end
            3'd1: begin
              for (int i = 0; i < 9; i++) begin
                data_a[i] <= checksum_tmp[i];
                data_b[i] <= checksum_tmp[i+9];
              end
              stage <= 3'd2;
              valid <= 0;
            end
            3'd2: begin
              for (int i = 0; i < 4; i++) begin
                data_a[i] <= checksum_tmp[i];
                data_b[i] <= checksum_tmp[i+4];
              end
              data_a[4] <= checksum_tmp[8];
              data_b[4] <= 0;
              stage <= 3'd3;
              valid <= 0;
            end
            3'd3: begin
              for (int i = 0; i < 2; i++) begin
                data_a[i] <= checksum_tmp[i];
                data_b[i] <= checksum_tmp[i+2];
              end
              data_a[2] <= checksum_tmp[4];
              data_b[2] <= 0;
              stage <= 3'd4;
              valid <= 0;
            end
            3'd4: begin
              data_a[0] <= checksum_tmp[0];
              data_b[0] <= checksum_tmp[1];
              data_a[1] <= checksum_tmp[2];
              data_b[1] <= 0;
              stage <= 3'd5;
              valid <= 0;
            end
            3'd5: begin
              data_a[0] <= checksum_tmp[0];
              data_b[0] <= checksum_tmp[1];
              valid <= 1;
              stage <= 3'd0;
            end
            default: begin
              stage <= 0;
              valid <= 0;
            end
          endcase
        end else begin
          stage <= 0;
        end
      end else begin
        stage <= 0;
        valid <= 0;
      end
    end
  end
endmodule


// Util : Bitwise flip. The entire input will be bitwise flipped.
module bytewise_flipper #(
    parameter BEAT_WIDTH = 8 * 56
) (
    input  wire [BEAT_WIDTH-1:0] data_in,
    output reg  [BEAT_WIDTH-1:0] data_out
);

  always_comb begin
    for (int i = 0; i < BEAT_WIDTH / 8; i = i + 1) begin
      data_out[(i*8)+:8] = data_in[(BEAT_WIDTH-i*8)-1-:8];
    end
  end
endmodule
