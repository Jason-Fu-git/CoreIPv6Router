`timescale 1ns / 1ps

// Example Frame Data Path.

`include "frame_datapath.vh"

module frame_datapath #(
    parameter DATA_WIDTH = 64,
    parameter ID_WIDTH   = 3
) (
    input wire eth_clk,
    input wire reset,

    input wire [DATA_WIDTH - 1:0] s_data,
    input wire [DATA_WIDTH / 8 - 1:0] s_keep,
    input wire s_last,
    input wire [DATA_WIDTH / 8 - 1:0] s_user,
    input wire [ID_WIDTH - 1:0] s_id,
    input wire s_valid,
    output wire s_ready,

    output wire [DATA_WIDTH - 1:0] m_data,
    output wire [DATA_WIDTH / 8 - 1:0] m_keep,
    output wire m_last,
    output wire [DATA_WIDTH / 8 - 1:0] m_user,
    output wire [ID_WIDTH - 1:0] m_dest,
    output wire m_valid,
    input wire m_ready,

    // added ip addrs and valids
    input wire [127:0] ip_addr_0,
    input wire [127:0] ip_addr_1,
    input wire [127:0] ip_addr_2,
    input wire [127:0] ip_addr_3,

    // added mac addrs
    input wire [47:0] mac_addr_0,
    input wire [47:0] mac_addr_1,
    input wire [47:0] mac_addr_2,
    input wire [47:0] mac_addr_3,

    input wire cpu_clk,
    input wire cpu_rst_p,
    input wire [31:0] cpu_adr,
    input wire [31:0] cpu_dat_in,
    output reg [31:0] cpu_dat_out,
    input wire cpu_wea,
    input wire cpu_stb,
    output reg cpu_ack,

    // dma interface
    output frame_beat dma_in,
    input wire dma_in_ready,

    input frame_beat dma_out,
    output reg dma_out_ready,

    input wire [15:0] dma_checksum,
    input wire dma_checksum_valid,

    // next hop table
    input  wire [127:0] nexthop_ip6_addr,
    input  wire [  1:0] nexthop_port_id,
    output reg  [  4:0] nexthop_addr
);

  frame_beat in8, in;
  wire in_ready;

  always_comb begin
    in8.meta = 0;
    in8.valid = s_valid;
    in8.data = s_data;
    in8.keep = s_keep;
    in8.last = s_last;
    in8.meta.id = s_id;
    in8.user = s_user;
  end

  // Track frames and figure out when it is the first beat.
  always @(posedge eth_clk or posedge reset) begin
    if (reset) begin
      in8.is_first <= 1'b1;
    end else begin
      if (in8.valid && s_ready) begin
        in8.is_first <= in8.last;
      end
    end
  end

  // README: Here, we use a width upsizer to change the width to 56 bytes
  // (MAC 14 + IPv6 40 + round up 2) to ensure that L2 (MAC) and L3 (IPv6) headers appear
  // in one beat (the first beat) facilitating our processing.
  // You can remove this.
  frame_beat_width_converter #(DATA_WIDTH, DATAW_WIDTH) frame_beat_upsizer (
      .clk(eth_clk),
      .rst(reset),

      .in(in8),
      .in_ready(s_ready),
      .out(in),
      .out_ready(in_ready)
  );

  wire out_ready;

  // ======================= Your code here. =====================================
  // See the guide to figure out what you need to do with frames.
  wire [3:0][127:0] ipv6_addrs;
  wire [3:0][47:0] mac_addrs;  // from reg to wire as we don't need them changed
  /* // ip config through buttons and switches
    addr_controller addr_controller_i(
        .clk(eth_clk),
        .rst(reset),
        .mac_addr_out(mac_addrs),
        .ipv6_addr_out(ipv6_addrs)
    );
    */

  assign ipv6_addrs[0] = ip_addr_0;
  assign ipv6_addrs[1] = ip_addr_1;
  assign ipv6_addrs[2] = ip_addr_2;
  assign ipv6_addrs[3] = ip_addr_3;

  // mac addresses are set when reset and then fixed
  assign mac_addrs[0]  = mac_addr_0;
  assign mac_addrs[1]  = mac_addr_1;
  assign mac_addrs[2]  = mac_addr_2;
  assign mac_addrs[3]  = mac_addr_3;

  // ipv6 addresses are set by the addr_controller

  frame_beat out;

  frame_beat ns_in, na_in, fw_in, rip_in;
  frame_beat ns_out, fw_out, nud_out, rip_out;
  logic ns_in_valid, na_in_valid, fw_in_valid, rip_in_valid;
  logic ns_in_ready, na_in_ready, fw_in_ready, rip_in_ready;
  logic ns_out_valid, fw_out_valid, nud_out_valid, rip_out_valid;
  logic ns_out_ready, fw_out_ready, nud_out_ready, rip_out_ready;
  logic ns_cache_valid, na_cache_valid;
  logic ns_cache_ready, na_cache_ready;
  cache_entry ns_cache_entry, na_cache_entry, cache_w, cache_w_buffer;
  logic cache_wea_p, cache_wea_p_buffer, cache_exists0, cache_exists1;
  logic nud_we_p;

  logic [4:0] trie128_next_hop;

  logic [127:0] nud_exp_addr, cache_ip6_addr0_i, cache_ip6_addr1_i;
  logic [1:0] nud_iface;
  logic [47:0] cache_mac_addr0_o, cache_mac_addr1_o;
  logic [1:0] cache_iface0_i, cache_iface1_i;

  fw_frame_beat_t fwt_in, fwt_out;
  logic fwt_in_ready, fwt_out_ready;
  logic trie128_out_ready;

  localparam BRAM_DATA_WIDTH = 320;
  localparam BRAM_ADDR_WIDTH = 5;
  reg bram_rea_p;
  reg bram_wea_p;
  reg bram_ack_p;
  reg [BRAM_ADDR_WIDTH-1:0] bram_addr_r;
  reg [BRAM_ADDR_WIDTH-1:0] bram_addr_w;
  reg [BRAM_DATA_WIDTH-1:0] bram_data_w;
  reg [BRAM_DATA_WIDTH-1:0] bram_data_r;


  always_ff @(posedge eth_clk) begin : CACHE_W_BUFFER
    if (reset) begin
      cache_w_buffer <= 0;
      cache_wea_p_buffer <= 0;
    end else begin
      cache_w_buffer <= cache_w;
      cache_wea_p_buffer <= cache_wea_p;
    end
  end

  neighbor_cache neighbor_cache_i (
      .clk  (eth_clk),
      .rst_p(reset),

      .r_IPv6_addr_0(cache_ip6_addr0_i),
      .r_port_id_0  (cache_iface0_i),
      .r_MAC_addr_0 (cache_mac_addr0_o),
      .r_exists_0   (cache_exists0),

      .r_IPv6_addr_1(cache_ip6_addr1_i),
      .r_port_id_1  (cache_iface1_i),
      .r_MAC_addr_1 (cache_mac_addr1_o),
      .r_exists_1   (cache_exists1),

      .w_IPv6_addr(cache_w_buffer.ip6_addr),
      .w_port_id  (cache_w_buffer.iface),
      .w_MAC_addr (cache_w_buffer.mac_addr),
      .wea_p      (cache_wea_p_buffer),

      .nud_probe      (nud_we_p),
      .probe_IPv6_addr(nud_exp_addr),
      .probe_port_id  (nud_iface)
  );



  trie128 forward_table_i (
      .clk  (eth_clk),
      .rst_p(reset),

      .in (fwt_in),
      .out(fwt_out),

      .in_ready (fwt_in_ready),
      .out_ready(fwt_out_ready),

      .in_valid (fwt_in.valid),
      .out_valid(trie128_out_ready),

      .addr(fwt_in.data.data.ip6.dst),
      .next_hop(trie128_next_hop),
      // .next_hop_ip6(trie128_ip6_addr),
      // .next_hop_iface(trie128_port_id),
      .default_next_hop(0),

      .cpu_clk(cpu_clk),
      .cpu_rst_p(cpu_rst_p),
      .cpu_adr_raw(cpu_adr),
      .cpu_dat_in_raw(cpu_dat_in),
      .cpu_dat_out_raw(cpu_dat_out),
      .cpu_wea_raw(cpu_wea),
      .cpu_stb_raw(cpu_stb),
      .cpu_ack_raw(cpu_ack)
  );

  assign rip_in = dma_out;

  always_comb begin : RIP_IN_VALID
    rip_in_valid = rip_in.valid;
    if (rip_in.is_first && !dma_checksum_valid) begin
      rip_in_valid = 0;
    end
  end

  always_comb begin : DMA_OUT_READY
    dma_out_ready = rip_in_ready;
    if (rip_in.is_first && !dma_checksum_valid) begin
      dma_out_ready = 0;
    end
  end

  pipeline_rip pipeline_rip_i (
      .clk  (eth_clk),
      .rst_p(reset),

      .in_valid (rip_in_valid),
      .in_ready (rip_in_ready),
      .out_valid(rip_out_valid),
      .out_ready(rip_out_ready),

      .in (rip_in),
      .out(rip_out),

      .cache_r_IPv6_addr(cache_ip6_addr1_i),
      .cache_r_port_id  (cache_iface1_i),
      .cache_r_MAC_addr (cache_mac_addr1_o),
      .cache_r_exists   (cache_exists1),

      .checksum(dma_checksum),
      .checksum_valid(dma_checksum_valid)
  );
  pipeline_forward pipeline_forward_i (
      .clk  (eth_clk),
      .rst_p(reset),

      .in_valid (fw_in_valid),
      .in_ready (fw_in_ready),
      .out_valid(fw_out_valid),
      .out_ready(fw_out_ready),

      .in (fw_in),
      .out(fw_out),

      .cache_r_IPv6_addr(cache_ip6_addr0_i),
      .cache_r_port_id  (cache_iface0_i),
      .cache_r_MAC_addr (cache_mac_addr0_o),
      .cache_r_exists   (cache_exists0),

      .fwt_in          (fwt_in),
      .fwt_out         (fwt_out),
      .fwt_nexthop_addr(trie128_next_hop),
      .fwt_in_ready    (fwt_in_ready),
      .fwt_out_ready   (fwt_out_ready),

      .nexthop_addr     (nexthop_addr),
      .nexthop_IPv6_addr(nexthop_ip6_addr),
      .nexthop_port_id  (nexthop_port_id),

      .mac_addrs(mac_addrs)
  );

  pipeline_ns pipeline_ns_i (
      .clk(eth_clk),
      .rst_p(reset),
      .valid_i(ns_in_valid),
      .ready_i(ns_out_ready),
      .valid_o(ns_out_valid),
      .ready_o(ns_in_ready),
      .in(ns_in),
      .out(ns_out),
      .cache_ready(ns_cache_ready),
      .cache_wea_p(ns_cache_valid),
      .cache_out(ns_cache_entry),
      .mac_addrs(mac_addrs),
      .ipv6_addrs(ipv6_addrs)
  );
  pipeline_na pipeline_na_i (
      .clk(eth_clk),
      .rst_p(reset),
      .valid_i(na_in_valid),
      .ready_i(na_cache_ready),
      .valid_o(na_cache_valid),
      .ready_o(na_in_ready),
      .in(na_in),
      .out(na_cache_entry)
  );
  pipeline_nud pipeline_nud_i (
      .clk(eth_clk),
      .rst_p(reset),
      .we_i(nud_we_p),
      .tgt_addr_i(nud_exp_addr),
      .ip6_addr_i(ipv6_addrs[nud_iface]),
      .mac_addr_i(mac_addrs[nud_iface]),
      .iface_i(nud_iface),
      .ready_i(nud_out_ready),
      .out(nud_out),
      .valid_o(nud_out_valid)
  );
  in_arbiter in_arbiter_i (
      .clk(eth_clk),
      .rst_p(reset),
      .in(in),
      .in_valid(in.valid),
      .ns_ready(ns_in_ready),
      .na_ready(na_in_ready),
      .fw_ready(fw_in_ready),
      .rip_ready(dma_in_ready),
      .out_ns(ns_in),
      .out_na(na_in),
      .out_fw(fw_in),
      .out_rip(dma_in),
      .ns_valid(ns_in_valid),
      .na_valid(na_in_valid),
      .fw_valid(fw_in_valid),
      .rip_valid(),
      .in_ready(in_ready)
  );
  out_arbiter out_arbiter_i (
      .clk(eth_clk),
      .rst_p(reset),
      .in_ns(ns_out),
      .in_fw(fw_out),
      .in_nud(nud_out),
      .in_rip(rip_out),
      .ns_valid(ns_out_valid),
      .fw_valid(fw_out_valid),
      .nud_valid(nud_out_valid),
      .rip_valid(rip_out_valid),
      .out_ready(out_ready),
      .out(out),
      .ns_ready(ns_out_ready),
      .fw_ready(fw_out_ready),
      .nud_ready(nud_out_ready),
      .rip_ready(rip_out_ready)
  );
  cache_arbiter cache_arbiter_i (
      .clk(eth_clk),
      .rst_p(reset),
      .ns_valid(ns_cache_valid),
      .na_valid(na_cache_valid),
      .ns_in(ns_cache_entry),
      .na_in(na_cache_entry),
      .ns_ready(ns_cache_ready),
      .na_ready(na_cache_ready),
      .out(cache_w),
      .wea_p(cache_wea_p)
  );

  // ======================= Your code end.  =====================================

  // always @ (*)
  // begin
  // out.meta.dest = 0;  // All frames are forwarded to interface 0!
  // if (`should_handle(in)) begin
  //     out = in;
  //     out.data.src = in.data.dst;
  //     out.data.dst = in.data.src;
  // end else begin
  //     out = in;
  // end
  // end

  //assign in_ready = out_ready || !out.valid;

  reg out_is_first;
  always @(posedge eth_clk or posedge reset) begin
    if (reset) begin
      out_is_first <= 1'b1;
    end else begin
      if (out.valid && out_ready) begin
        out_is_first <= out.last;
      end
    end
  end

  reg [ID_WIDTH - 1:0] dest;
  reg drop_by_prev;  // Dropped by the previous frame?
  always @(posedge eth_clk or posedge reset) begin
    if (reset) begin
      dest <= 0;
      drop_by_prev <= 1'b0;
    end else begin
      if (out_is_first && out.valid && out_ready) begin
        dest <= out.meta.dest;
        drop_by_prev <= out.meta.drop_next;
      end
    end
  end

  // Rewrite dest.
  wire [ID_WIDTH - 1:0] dest_current = out_is_first ? out.meta.dest : dest;

  frame_beat filtered;
  wire filtered_ready;

  frame_filter #(
      .DATA_WIDTH(DATAW_WIDTH),
      .ID_WIDTH  (ID_WIDTH)
  ) frame_filter_i (
      .eth_clk(eth_clk),
      .reset  (reset),

      .s_data(out.data),
      .s_keep(out.keep),
      .s_last(out.last),
      .s_user(out.user),
      .s_id(dest_current),
      .s_valid(out.valid),
      .s_ready(out_ready),

      .drop(out.meta.drop || drop_by_prev),

      .m_data(filtered.data),
      .m_keep(filtered.keep),
      .m_last(filtered.last),
      .m_user(filtered.user),
      .m_id(filtered.meta.dest),
      .m_valid(filtered.valid),
      .m_ready(filtered_ready)
  );

  // README: Change the width back. You can remove this.
  frame_beat out8;
  frame_beat_width_converter #(DATAW_WIDTH, DATA_WIDTH) frame_beat_downsizer (
      .clk(eth_clk),
      .rst(reset),

      .in(filtered),
      .in_ready(filtered_ready),
      .out(out8),
      .out_ready(m_ready)
  );

  assign m_valid = out8.valid;
  assign m_data  = out8.data;
  assign m_keep  = out8.keep;
  assign m_last  = out8.last;
  assign m_dest  = out8.meta.dest;
  assign m_user  = out8.user;
endmodule
