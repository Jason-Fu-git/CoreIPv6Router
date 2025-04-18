`timescale 1ns / 1ps
`include "frame_datapath.vh"


module pipeline_forward (
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

    // forward table
    output fw_frame_beat_t         fwt_in,
    input  fw_frame_beat_t         fwt_out,
    input  wire            [  4:0] fwt_nexthop_addr,
    input  wire                    fwt_in_ready,
    output reg                     fwt_out_ready,
    output reg             [127:0] fwt_addr,

    // nexthop lookup
    output reg  [  4:0] nexthop_addr,
    input  wire [127:0] nexthop_IPv6_addr,
    input  wire [  1:0] nexthop_port_id,

    // Address config
    input wire [3:0][47:0] mac_addrs,  // router MAC address


    // All NUD signals will be hold for one cycle when cache miss
    output reg nud_probe,  // FLAG : whether the external module should probe the IPv6 address
    output reg [127:0] probe_IPv6_addr,  // Key : IPv6 address to probe
    output reg [1:0] probe_port_id  // Value : port id to probe
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
  assign in_ready = buffer_ready;

  always_ff @(posedge clk) begin : FW_IN_REG
    if (rst_p) begin
      in_buffer <= 0;
    end else begin
      if (buffer_ready) begin
        in_buffer.valid <= in_valid;
        in_buffer.error <= in_error_next;
        if (in_valid) begin
          in_buffer.data <= in;
        end
      end
    end
  end

  // =======================
  // Forwarding table
  // =======================
  assign buffer_ready = fwt_in_ready || (!in_buffer.valid);

  logic [127:0] fwt_addr_rev;

  always_ff @(posedge clk) begin : FW_FWT_IN_REG
    if (rst_p) begin
      fwt_in <= 0;
      fwt_addr_rev <= 0;
    end else begin
      if (fwt_in_ready) begin
        fwt_in <= in_buffer;
        fwt_addr_rev <= in_buffer.data.data.ip6.dst;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < 16; i = i + 1) begin
      fwt_addr[i*8+:8] = {
        fwt_addr_rev[i*8+0],
        fwt_addr_rev[i*8+1],
        fwt_addr_rev[i*8+2],
        fwt_addr_rev[i*8+3],
        fwt_addr_rev[i*8+4],
        fwt_addr_rev[i*8+5],
        fwt_addr_rev[i*8+6],
        fwt_addr_rev[i*8+7]
      };
    end
  end

  // ======================
  // Nexthop lookup
  // ======================
  fw_frame_beat_t nexthop_beat;
  logic nexthop_ready;

  always_ff @(posedge clk) begin : NEXTHOP_BEAT
    if (rst_p) begin
      nexthop_beat <= 0;
    end else if (nexthop_ready) begin
      nexthop_beat <= fwt_out;
      nexthop_addr <= fwt_nexthop_addr;
    end
  end

  assign fwt_out_ready = nexthop_ready || (!fwt_out.valid);


  // extra pipeline stage for neighbor cache lookup
  fw_frame_beat_t nc_beat;
  logic [127:0] nc_IPv6_addr;
  logic [1:0] nc_port_id;
  logic nc_ready;

  assign nexthop_ready = nc_ready || (!nexthop_beat.valid);


  always_ff @(posedge clk) begin : NC_BEAT
    if (rst_p) begin
      nc_beat <= 0;
    end else if (nc_ready) begin
      nc_beat      <= nexthop_beat;
      nc_IPv6_addr <= nexthop_IPv6_addr;
      nc_port_id   <= nexthop_port_id;
    end
  end


  // Buffer for nc_beat
  fw_frame_beat_t         nc_beat_buffer;
  logic           [127:0] nc_IPv6_addr_buffer;
  logic           [  1:0] nc_port_id_buffer;

  always_ff @(posedge clk) begin : NC_BEAT_BUFFER
    if (rst_p) begin
      nc_beat_buffer <= 0;
    end else if (nc_ready) begin
      nc_beat_buffer      <= nexthop_beat;
      nc_IPv6_addr_buffer <= nexthop_IPv6_addr;
      nc_port_id_buffer   <= nexthop_port_id;
    end
  end


  // =======================
  // Neighbor Cache
  // =======================

  logic cache_ready;
  fw_frame_beat_t cache_beat;
  fw_frame_beat_t cache_beat_comb;


  always_ff @(posedge clk) begin : NC_READY
    if (rst_p) begin
      nc_ready <= 0;
    end else begin
      nc_ready <= cache_ready;
    end
  end

  always_comb begin : FW_CACHE_SIGNALS
    cache_r_IPv6_addr = nc_IPv6_addr;
    cache_r_port_id   = nc_port_id;
    cache_beat_comb   = nc_beat;
    if (cache_ready && !nc_ready) begin
      cache_r_IPv6_addr = nc_IPv6_addr_buffer;
      cache_r_port_id   = nc_port_id_buffer;
      cache_beat_comb   = nc_beat_buffer;
    end
  end

  always_ff @(posedge clk) begin : NUD
    if (rst_p) begin
      nud_probe       <= 0;
      probe_IPv6_addr <= 0;
      probe_port_id   <= 0;
    end else begin
      nud_probe       <= cache_beat_comb.valid && cache_beat_comb.data.is_first && (!cache_r_exists);
      probe_IPv6_addr <= cache_r_IPv6_addr;
      probe_port_id   <= cache_r_port_id;
    end
  end

  logic [1:0] cache_r_port_id_reg;
  always_ff @(posedge clk) begin : FW_CACHE_R_PORT_REG
    if (rst_p) begin
      cache_r_port_id_reg <= 0;
    end else begin
      if (cache_beat_comb.data.is_first) begin
        cache_r_port_id_reg <= cache_r_port_id;
      end
    end
  end

  always_ff @(posedge clk) begin : FW_CACHE_REG
    if (rst_p) begin
      cache_beat <= 0;
    end else begin
      if (cache_ready) begin
        cache_beat.valid <= cache_beat_comb.valid;
        if (cache_beat_comb.valid) begin
          if (cache_beat_comb.data.is_first) begin
            if (cache_beat_comb.error == ERR_NONE) begin
              if (cache_r_exists) begin
                cache_beat.error                <= ERR_NONE;

                // frame_beat properties
                cache_beat.data.keep            <= cache_beat_comb.data.keep;
                cache_beat.data.last            <= cache_beat_comb.data.last;
                cache_beat.data.user            <= cache_beat_comb.data.user;
                cache_beat.data.valid           <= cache_beat_comb.data.valid;
                cache_beat.data.is_first        <= cache_beat_comb.data.is_first;

                // frame_meta properties
                cache_beat.data.meta.id         <= cache_beat_comb.data.meta.id;
                cache_beat.data.meta.dest       <= cache_r_port_id;
                cache_beat.data.meta.drop       <= cache_beat_comb.data.meta.drop;
                cache_beat.data.meta.dont_touch <= cache_beat_comb.data.meta.dont_touch;
                cache_beat.data.meta.drop_next  <= cache_beat_comb.data.meta.drop_next;

                // ether_hdr properties
                cache_beat.data.data.ethertype  <= cache_beat_comb.data.data.ethertype;
                cache_beat.data.data.src        <= cache_beat_comb.data.data.src;
                cache_beat.data.data.dst        <= cache_r_MAC_addr;
                cache_beat.data.data.ip6        <= cache_beat_comb.data.data.ip6;

              end else begin
                cache_beat.error <= ERR_NC_MISS;
                cache_beat.data  <= cache_beat_comb.data;
              end
            end else begin
              cache_beat.error <= cache_beat_comb.error;
              cache_beat.data  <= cache_beat_comb.data;
            end
          end else begin
            // Not the first beat
            cache_beat.error                <= cache_beat_comb.error;

            // frame_beat properties
            cache_beat.data.keep            <= cache_beat_comb.data.keep;
            cache_beat.data.last            <= cache_beat_comb.data.last;
            cache_beat.data.user            <= cache_beat_comb.data.user;
            cache_beat.data.valid           <= cache_beat_comb.data.valid;
            cache_beat.data.is_first        <= cache_beat_comb.data.is_first;

            // frame_meta properties
            cache_beat.data.meta.id         <= cache_beat_comb.data.meta.id;
            cache_beat.data.meta.dest       <= cache_r_port_id_reg;
            cache_beat.data.meta.drop       <= cache_beat_comb.data.meta.drop;
            cache_beat.data.meta.dont_touch <= cache_beat_comb.data.meta.dont_touch;
            cache_beat.data.meta.drop_next  <= cache_beat_comb.data.meta.drop_next;

            // payload
            cache_beat.data.data            <= cache_beat_comb.data.data;
          end
        end
      end
    end
  end

  // =======================
  // Output
  // =======================
  assign cache_ready = out_ready || (!cache_beat.valid);

  logic [47:0] src_MAC_addr;
  always_comb begin : FW_OUT_SRC
    case (cache_beat.data.meta.dest)
      2'd0: begin
        src_MAC_addr = mac_addrs[0];
      end
      2'd1: begin
        src_MAC_addr = mac_addrs[1];
      end
      2'd2: begin
        src_MAC_addr = mac_addrs[2];
      end
      2'd3: begin
        src_MAC_addr = mac_addrs[3];
      end
      default: begin
        src_MAC_addr = 48'h0;
      end
    endcase
  end

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
            out.data.src             <= src_MAC_addr;
            out.data.dst             <= cache_beat.data.data.dst;

            // IPv6 header properties
            out.data.ip6.version     <= cache_beat.data.data.ip6.version;
            out.data.ip6.flow_hi     <= cache_beat.data.data.ip6.flow_hi;
            out.data.ip6.flow_lo     <= cache_beat.data.data.ip6.flow_lo;
            out.data.ip6.payload_len <= cache_beat.data.data.ip6.payload_len;
            out.data.ip6.next_hdr    <= cache_beat.data.data.ip6.next_hdr;
            out.data.ip6.hop_limit   <= cache_beat.data.data.ip6.hop_limit - 1;
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




