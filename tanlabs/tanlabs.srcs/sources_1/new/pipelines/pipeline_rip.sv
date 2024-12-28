`timescale 1ns / 1ps
`include "frame_datapath.vh"

module pipeline_rip (
    input wire clk,
    input wire rst_p,

    input  wire in_valid,
    input  wire out_ready,
    output reg  out_valid,
    output reg  in_ready,

    input  frame_beat in,
    output frame_beat out,

    // neighbor cache
    output reg  [127:0] cache_r_IPv6_addr,
    output reg  [  1:0] cache_r_port_id,
    input  wire [ 47:0] cache_r_MAC_addr,
    input  wire         cache_r_exists,

    // Checksum
    input wire [15:0] checksum,
    input wire checksum_valid // IMPORTANT: In order to make this design work, FIFO must at least hold 2 MTU
);

  fw_error_t in_error_next;

  always_comb begin : FW_INPUT_TYPE
    in_error_next = ERR_NONE;
    if (`should_handle(in)) begin
      if (in.data.ip6.version == 6) begin
        if (in.data.ip6.hop_limit > 1) begin
          in_error_next = ERR_NONE;
        end else begin
          in_error_next = ERR_HOP_LIMIT;
        end
      end else begin
        in_error_next = ERR_WRONG_TYPE;
      end
    end
  end

  // =======================
  // Input Buffer
  // =======================
  fw_frame_beat_t in_buffer;
  logic buffer_ready;
  logic is_second;
  assign in_ready = buffer_ready;

  frame_beat in_buffer_data;
  always_comb begin : FW_IN_BUFFER_DATA
    in_buffer_data = in;
    if (is_second) begin
      in_buffer_data.data[39:32] = checksum[15:8];
      in_buffer_data.data[47:40] = checksum[7:0];
    end
  end

  always_ff @(posedge clk) begin : FW_IN_REG
    if (rst_p) begin
      in_buffer <= 0;
      is_second <= 0;
    end else begin
      if (buffer_ready) begin
        in_buffer.valid <= in_valid;
        in_buffer.error <= in_error_next;
        if (in_valid) begin
          in_buffer.data <= in_buffer_data;
          // Set is_second
          if (in.is_first) begin
            is_second <= 1;
          end else if (in.last) begin
            is_second <= 0;
          end else begin
            is_second <= 0;
          end
        end
      end
    end
  end

  assign buffer_ready = cache_ready || (!in_buffer.valid);

  // =======================
  // Neighbor Cache
  // =======================
  logic cache_ready;
  fw_frame_beat_t cache_beat;

  always_comb begin : FW_CACHE_SIGNALS
    cache_r_IPv6_addr = in_buffer.data.data.ip6.dst;
    cache_r_port_id   = in_buffer.data.meta.dest[1:0];
  end

  always_ff @(posedge clk) begin : FW_CACHE_REG
    if (rst_p) begin
      cache_beat <= 0;
    end else begin
      if (cache_ready) begin
        cache_beat.valid <= in_buffer.valid;
        if (in_buffer.valid) begin
          if (in_buffer.data.is_first) begin
            if (in_buffer.error == ERR_NONE) begin
              if (cache_r_exists) begin
                cache_beat.error                <= ERR_NONE;

                // frame_beat properties
                cache_beat.data.keep            <= in_buffer.data.keep;
                cache_beat.data.last            <= in_buffer.data.last;
                cache_beat.data.user            <= in_buffer.data.user;
                cache_beat.data.valid           <= in_buffer.data.valid;
                cache_beat.data.is_first        <= in_buffer.data.is_first;

                // frame_meta properties
                cache_beat.data.meta.id         <= in_buffer.data.meta.id;
                cache_beat.data.meta.dest       <= in_buffer.data.meta.dest;
                cache_beat.data.meta.drop       <= in_buffer.data.meta.drop;
                cache_beat.data.meta.dont_touch <= in_buffer.data.meta.dont_touch;
                cache_beat.data.meta.drop_next  <= in_buffer.data.meta.drop_next;

                // ether_hdr properties
                cache_beat.data.data.ethertype  <= in_buffer.data.data.ethertype;
                cache_beat.data.data.src        <= in_buffer.data.data.src;
                cache_beat.data.data.dst        <= cache_r_MAC_addr;
                cache_beat.data.data.ip6        <= in_buffer.data.data.ip6;
              end else begin
                cache_beat.error <= ERR_NC_MISS;
                cache_beat.data  <= in_buffer.data;
              end
            end else begin
              cache_beat.error <= in_buffer.error;
              cache_beat.data  <= in_buffer.data;
            end
          end else begin
            // Not the first beat
            cache_beat.error                <= in_buffer.error;

            // frame_beat properties
            cache_beat.data.keep            <= in_buffer.data.keep;
            cache_beat.data.last            <= in_buffer.data.last;
            cache_beat.data.user            <= in_buffer.data.user;
            cache_beat.data.valid           <= in_buffer.data.valid;
            cache_beat.data.is_first        <= in_buffer.data.is_first;

            // frame_meta properties
            cache_beat.data.meta.id         <= in_buffer.data.meta.id;
            cache_beat.data.meta.dest       <= cache_beat.data.meta.dest;
            cache_beat.data.meta.drop       <= in_buffer.data.meta.drop;
            cache_beat.data.meta.dont_touch <= in_buffer.data.meta.dont_touch;
            cache_beat.data.meta.drop_next  <= in_buffer.data.meta.drop_next;

            // payload
            cache_beat.data.data            <= in_buffer.data.data;
          end
        end
      end
    end
  end

  // =======================
  // Output
  // =======================
  assign cache_ready = out_ready || (!cache_beat.valid);


  always_ff @(posedge clk) begin : FW_OUT_REG
    if (rst_p) begin
      out <= 0;
    end else begin
      if (out_ready) begin
        if (cache_beat.valid) begin
          if (cache_beat.data.is_first) begin
            // frame_beat properties
            out.keep      <= cache_beat.data.keep;
            out.last      <= cache_beat.data.last;
            out.user      <= cache_beat.data.user;
            out.valid     <= cache_beat.data.valid;
            out.is_first  <= cache_beat.data.is_first;

            // frame_meta properties
            out.meta.id   <= cache_beat.data.meta.id;
            out.meta.dest <= cache_beat.data.meta.dest;
            if (cache_beat.error != ERR_NONE) begin
              out.meta.drop <= 1;
            end else begin
              out.meta.drop <= cache_beat.data.meta.drop;
            end
            out.meta.dont_touch      <= cache_beat.data.meta.dont_touch;
            out.meta.drop_next       <= cache_beat.data.meta.drop_next;

            // ether_hdr properties
            out.data.ethertype       <= cache_beat.data.data.ethertype;
            out.data.src             <= cache_beat.data.data.src;
            out.data.dst             <= cache_beat.data.data.dst;

            // IPv6 header properties
            out.data.ip6.version     <= cache_beat.data.data.ip6.version;
            out.data.ip6.flow_hi     <= cache_beat.data.data.ip6.flow_hi;
            out.data.ip6.flow_lo     <= cache_beat.data.data.ip6.flow_lo;
            out.data.ip6.payload_len <= cache_beat.data.data.ip6.payload_len;
            out.data.ip6.next_hdr    <= cache_beat.data.data.ip6.next_hdr;
            out.data.ip6.hop_limit   <= cache_beat.data.data.ip6.hop_limit;
            out.data.ip6.src         <= cache_beat.data.data.ip6.src;
            out.data.ip6.dst         <= cache_beat.data.data.ip6.dst;
            out.data.ip6.p           <= cache_beat.data.data.ip6.p;
          end else begin
            // Not the first beat
            out <= cache_beat.data;
          end

        end else begin
          out.valid <= 0;
        end
      end
    end
  end

  assign out_valid = out.valid;

endmodule




