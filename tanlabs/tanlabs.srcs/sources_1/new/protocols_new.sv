`timescale 1ns / 1ps

`include "frame_datapath.vh"

module datapath_sm (
    input wire clk,
    input wire rst_p,

    input frame_beat in,        // now input pack
    input wire       s_ready,   // input is valid
    input wire       out_ready, // output pack can be sent

    output reg        in_ready,  // ready to receive the next pack
    output frame_beat out,       // output pack, `out.valid` indicates validity

    input wire [ 47:0] mac_addrs [0:3],  // router MAC address
    input wire [127:0] ipv6_addrs[0:3]   // router IPv6 address
);

  // =============================================================
  //  Top level state definition
  // =============================================================

  // DP: DataPath states
  typedef enum logic [3:0] {
    DP_IDLE,  // Wait for the first pack
    DP_NS,    // Received an NS pack
    DP_NA,    // Received an NA pack
    DP_NUD,   // Time to do NUD when free
    DP_FWD    // Forward everything else
  } dp_state_t;

  // Top level states, transition conditions at the end
  dp_state_t state, next_state, state_reg, next_state_reg;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      state <= DP_IDLE;
      state_reg <= DP_IDLE;
      next_state_reg <= DP_IDLE;
    end else begin
      state <= next_state;
      state_reg <= state;
      next_state_reg <= next_state;
    end
  end

  // =============================================================
  //  NS state definition
  // =============================================================

  typedef enum logic [3:0] {
    NS_IDLE,         // Wait for an NS pack
    NS_WAIT,         // Wait for the second pack to arrive
    NS_CHECKSUM_NS,  // Wait for NS checksum
    NS_SEND_1,       // Send the first pack of NA
    NS_CHECKSUM_NA,  // Wait for NA checksum (normally needn't wait)
    NS_SEND_2        // Send the second pack of NA
  } ns_state_t;

  ns_state_t ns_state, ns_next_state, ns_state_reg, ns_next_state_reg;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      ns_state <= NS_IDLE;
      ns_state_reg <= NS_IDLE;
      ns_next_state_reg <= NS_IDLE;
    end else begin
      ns_state <= ns_next_state;
      ns_state_reg <= ns_state;
      ns_next_state_reg <= ns_next_state;
    end
  end

  // =============================================================
  //  NA state definition
  // =============================================================

  typedef enum logic [3:0] {
    NA_IDLE ,    // Wait for an NA pack
    NA_WAIT ,    // Wait for the second pack to arrive
    NA_CHECKSUM, // Wait for NA checksum
    NA_CACHE     // Write ND cache
  } na_state_t;

  na_state_t na_state, na_next_state, na_state_reg, na_next_state_reg;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      na_state <= NA_IDLE;
      na_state_reg <= NA_IDLE;
      na_next_state_reg <= NA_IDLE;
    end else begin
      na_state <= na_next_state;
      na_state_reg <= na_state;
      na_next_state_reg <= na_next_state;
    end
  end

  // =============================================================
  //  NUD state definition
  // =============================================================

  typedef enum logic [3:0] {
    NUD_IDLE,    // Wait for NUD
    NUD_SEND_1,  // Send the first pack of NS
    NUD_WAIT,    // Wait for NS checksum
    NUD_SEND_2   // Send the second pack of NS
  } nud_state_t;

  nud_state_t nud_state, nud_next_state, nud_state_reg, nud_next_state_reg;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      nud_state <= NUD_IDLE;
      nud_state_reg <= NUD_IDLE;
      nud_next_state_reg <= NUD_IDLE;
    end else begin
      nud_state <= nud_next_state;
      nud_state_reg <= nud_state;
      nud_next_state_reg <= nud_next_state;
    end
  end

  // =============================================================
  //  FWD state definition
  // =============================================================

  typedef enum logic [2:0] {
    FW_IDLE,
    FW_FWT,  // Forward Table Query
    FW_NC,  // ND cache query
    FW_FW,  // Construct the pack to forward
    FW_SEND_1,  // Send the first pack
    FW_SEND_F,  // Send the following pack
    FW_DONE
  } fw_state_t;
  fw_state_t fw_state, fw_next_state;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      fw_state <= FW_IDLE;
    end else begin
      fw_state <= fw_next_state;
    end
  end

  // =============================================================
  //  ND cache state definition
  // =============================================================

  typedef enum logic [3:0] {
    CACHE_SLEEP,
    CACHE_REQUIRE_UPDATE,
    CACHE_READ,
    CACHE_READ_DONE,
    CACHE_SIGNAL_SENT
  } cache_state_t;

  cache_state_t cache_state, cache_next_state, cache_state_reg, cache_next_state_reg;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      cache_state <= CACHE_SLEEP;
      cache_state_reg <= CACHE_SLEEP;
      cache_next_state_reg <= CACHE_SLEEP;
    end else begin
      cache_state <= cache_next_state;
      cache_state_reg <= cache_state;
      cache_next_state_reg <= cache_next_state;
    end
  end

  // =============================================================
  //  Top level util-signals definition
  // =============================================================

  assign in_ready = (
           ((state == DP_IDLE) && (next_state != DP_NUD ))
        || ((state == DP_NS  ) && (ns_state   == NS_WAIT))
        || ((state == DP_NA  ) && (na_state   == NA_WAIT))
        || ((state == DP_FWD) && (fw_state == FW_SEND_F))
    );

  frame_beat       first_beat;  // The first pack, containing Ether/Ipv6 headers
  ether_hdr        in_ether_hdr;  // Ether header of the packet being handled now
  ip6_hdr          in_ip6_hdr;  // IPv6 header of the packet being handled now
  logic      [1:0] in_meta_src;  // Interface

  assign in_ether_hdr = first_beat.data;
  assign in_ip6_hdr   = first_beat.data.ip6;
  assign in_meta_src  = first_beat.meta.id;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      first_beat <= 0;
    end else begin
      // When the Ether/IPv6 header indicates that we should handle the packet, store the first pack
      if ((state == DP_IDLE) && (next_state != DP_IDLE) && (next_state != DP_NUD)) begin
        first_beat <= in;
      end
    end
  end

  // =============================================================
  //  NS signals definition
  // =============================================================

  NS_packet        ns_packet_i;  // temporal logic
  logic     [15:0] ns_checksum;  // combinational logic
  logic            ns_checksum_ea_p;  // temporal logic
  logic            ns_checksum_ok;  // temporal logic
  logic            ns_checksum_valid;  // combinational logic
  logic            ns_valid;  // combinational logic

  NA_packet        ns_na_packet_i;  // combinational logic, checksum 0
  logic     [15:0] ns_na_checksum;  // combinational logic
  logic     [15:0] ns_na_checksum_reg;  // temporal logic
  logic            ns_na_checksum_ea_p;  // temporal logic
  logic            ns_na_checksum_valid;  // combinational logic

  assign ns_valid = (
           (ns_packet_i.option.len > 0)
        && (ns_packet_i.icmpv6.target_addr[7:0] != 8'hff) // not multi-cast
      && (ns_checksum_ok) && (ns_na_packet_i.ether.ip6.src == ns_packet_i.icmpv6.target_addr));

  always_comb begin
    ns_na_packet_i.option.option_type = 8'd2;
    ns_na_packet_i.option.len = 8'd1;
    ns_na_packet_i.icmpv6.icmpv6_type = ICMPv6_HDR_TYPE_NA;  // 8'd136
    ns_na_packet_i.icmpv6.code = 8'd0;
    ns_na_packet_i.icmpv6.checksum = 16'd0;
    ns_na_packet_i.icmpv6.R = 1'b1;  // sent from router
    ns_na_packet_i.icmpv6.S = 1'b1;  // TODO: set the flag, now is default: sent as response to NS
    ns_na_packet_i.icmpv6.O = 1'b0;  // TODO: set the flag
    ns_na_packet_i.icmpv6.reserved_lo = 24'h0;
    ns_na_packet_i.icmpv6.reserved_hi = 5'h0;
    ns_na_packet_i.icmpv6.target_addr = in_ip6_hdr.src;
    ns_na_packet_i.ether.dst = in_ether_hdr.src;
    ns_na_packet_i.ether.ethertype = 16'hdd86;  // IPv6
    ns_na_packet_i.ether.ip6.dst = in_ip6_hdr.src;
    ns_na_packet_i.ether.ip6.next_hdr = IP6_HDR_TYPE_ICMPv6;  // 8'd58
    ns_na_packet_i.ether.ip6.hop_limit = IP6_HDR_HOP_LIMIT_DEFAULT;  // 8'd255
    ns_na_packet_i.ether.ip6.payload_len = {
      8'd32, 8'd0
    };  // 24 bytes for ICMPv6 header, 8 bytes for option
    ns_na_packet_i.ether.ip6.flow_lo = 24'b0;
    ns_na_packet_i.ether.ip6.flow_hi = 4'b0;
    ns_na_packet_i.ether.ip6.version = 4'd6;
    case (in_meta_src)
      2'd0: begin
        ns_na_packet_i.option.mac_addr = mac_addrs[0];
        ns_na_packet_i.ether.src       = mac_addrs[0];
        ns_na_packet_i.ether.ip6.src   = ipv6_addrs[0];
      end
      2'd1: begin
        ns_na_packet_i.option.mac_addr = mac_addrs[1];
        ns_na_packet_i.ether.src       = mac_addrs[1];
        ns_na_packet_i.ether.ip6.src   = ipv6_addrs[1];
      end
      2'd2: begin
        ns_na_packet_i.option.mac_addr = mac_addrs[2];
        ns_na_packet_i.ether.src       = mac_addrs[2];
        ns_na_packet_i.ether.ip6.src   = ipv6_addrs[2];
      end
      2'd3: begin
        ns_na_packet_i.option.mac_addr = mac_addrs[3];
        ns_na_packet_i.ether.src       = mac_addrs[3];
        ns_na_packet_i.ether.ip6.src   = ipv6_addrs[3];
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst_p) begin
      ns_packet_i         <= 0;
      ns_checksum_ea_p    <= 1'b0;
      ns_checksum_ok      <= 1'b0;
      ns_na_checksum_reg  <= 16'b0;
      ns_na_checksum_ea_p <= 1'b0;
    end else begin
      if (ns_checksum_valid) begin
        ns_checksum_ok <= (ns_checksum == 16'hffff);
      end
      if ((ns_state == NS_WAIT) && s_ready) begin
        ns_packet_i         <= {in.data, first_beat.data};
        ns_checksum_ea_p    <= 1'b1;
        ns_na_checksum_ea_p <= 1'b1;
      end else if ((ns_state == NS_SEND_1) && (ns_next_state != NS_SEND_1)) begin
        ns_checksum_ea_p <= 1'b0;
        ns_checksum_ok   <= 1'b0;
      end else if ((ns_state == NS_SEND_2) && (ns_next_state != NS_SEND_2)) begin
        ns_na_checksum_ea_p <= 1'b0;
      end
    end
  end

  checksum_calculator checksum_calculator_i_ns (
      .clk            (clk),
      .rst_p          (rst_p),
      .ip6_src        (ns_packet_i.ether.ip6.src),
      .ip6_dst        (ns_packet_i.ether.ip6.dst),
      .payload_length ({16'd0, ns_packet_i.ether.ip6.payload_len}),
      .next_header    (ns_packet_i.ether.ip6.next_hdr),
      .current_payload({ns_packet_i.option, ns_packet_i.icmpv6}),
      .mask           (~(256'd0)),
      .is_first       (1'b1),
      .ea_p           (ns_checksum_ea_p),
      .checksum       (ns_checksum),
      .valid          (ns_checksum_valid)
  );

  checksum_calculator checksum_calculator_i_ns_na (
      .clk            (clk),
      .rst_p          (rst_p),
      .ip6_src        (ns_na_packet_i.ether.ip6.src),
      .ip6_dst        (ns_na_packet_i.ether.ip6.dst),
      .payload_length ({16'd0, ns_na_packet_i.ether.ip6.payload_len}),
      .next_header    (ns_na_packet_i.ether.ip6.next_hdr),
      .current_payload({ns_na_packet_i.option, ns_na_packet_i.icmpv6}),
      .mask           (~(256'd0)),
      .is_first       (1'b1),
      .ea_p           (ns_na_checksum_ea_p),
      .checksum       (ns_na_checksum),
      .valid          (ns_na_checksum_valid)
  );

  // =============================================================
  //  NA signals definition
  // =============================================================

  NA_packet        na_packet_i;  // temporal logic
  logic     [15:0] na_checksum;  // combinational logic
  logic            na_checksum_ea_p;  // temporal logic
  logic            na_checksum_ok;  // temporal logic
  logic            na_checksum_valid;  // combinational logic
  logic            na_valid;  // combinational logic

  assign na_valid = ((na_packet_i.option.len > 0) && (na_checksum_ok));

  always_ff @(posedge clk) begin
    if (rst_p) begin
      na_packet_i      <= 0;
      na_checksum_ea_p <= 1'b0;
      na_checksum_ok   <= 1'b0;
    end else begin
      if (na_checksum_valid) begin
        na_checksum_ok <= (na_checksum == 16'hffff);
      end
      if ((na_state == NA_WAIT) && s_ready) begin
        na_packet_i      <= {in.data, first_beat.data};
        na_checksum_ea_p <= 1'b1;
      end else if ((na_state == NA_CACHE) && (na_next_state != NA_CACHE)) begin
        na_checksum_ea_p <= 1'b0;
        na_checksum_ok   <= 1'b0;
      end
    end
  end

  checksum_calculator checksum_calculator_i_na (
      .clk            (clk),
      .rst_p          (rst_p),
      .ip6_src        (na_packet_i.ether.ip6.src),
      .ip6_dst        (na_packet_i.ether.ip6.dst),
      .payload_length ({16'd0, na_packet_i.ether.ip6.payload_len}),
      .next_header    (na_packet_i.ether.ip6.next_hdr),
      .current_payload({na_packet_i.option, na_packet_i.icmpv6}),
      .mask           (~(256'd0)),
      .is_first       (1'b1),
      .ea_p           (na_checksum_ea_p),
      .checksum       (na_checksum),
      .valid          (na_checksum_valid)
  );

  // =============================================================
  //  NUD signals definition
  // =============================================================

  logic     [127:0] nud_exp_addr;  // expired address
  logic     [127:0] nud_ipv6_addr;
  logic     [ 47:0] nud_mac_addr;
  logic     [  1:0] nud_iface;
  logic             nud_we_p;
  NS_packet         nud_ns;
  logic     [ 15:0] nud_checksum;
  logic             nud_ns_valid;
  logic             nud_ack;
  logic     [  1:0] nud_iface_o;

  assign nud_ack = ((nud_state == NUD_SEND_2) && out_ready);

  always_comb begin
    case (nud_iface)
      2'd0: begin
        nud_mac_addr  = mac_addrs[0];
        nud_ipv6_addr = ipv6_addrs[0];
      end
      2'd1: begin
        nud_mac_addr  = mac_addrs[1];
        nud_ipv6_addr = ipv6_addrs[1];
      end
      2'd2: begin
        nud_mac_addr  = mac_addrs[2];
        nud_ipv6_addr = ipv6_addrs[2];
      end
      2'd3: begin
        nud_mac_addr  = mac_addrs[3];
        nud_ipv6_addr = ipv6_addrs[3];
      end
    endcase
  end

  nud nud_i (
      .clk       (clk),
      .rst       (rst_p),
      .we_i      (nud_we_p),
      .tgt_addr_i(nud_exp_addr),
      .ip6_addr_i(nud_ipv6_addr),
      .mac_addr_i(nud_mac_addr),
      .iface_i   (nud_iface),
      .ack_i     (nud_ack),
      .NS_o      (nud_ns),
      .NS_valid_o(nud_ns_valid),
      .iface_o   (nud_iface_o),
      .checksum_o(nud_checksum)
  );

  // =============================================================
  //  BRAM Controller
  // =============================================================

  localparam BRAM_DATA_WIDTH = 320;
  localparam BRAM_ADDR_WIDTH = 5;
  reg bram_rea_p;
  reg bram_wea_p;
  reg bram_ack_p;
  reg [BRAM_ADDR_WIDTH-1:0] bram_addr_r;
  reg [BRAM_ADDR_WIDTH-1:0] bram_addr_w;
  reg [BRAM_DATA_WIDTH-1:0] bram_data_w;
  reg [BRAM_DATA_WIDTH-1:0] bram_data_r;

  bram_controller #(
      .DATA_WIDTH(BRAM_DATA_WIDTH),
      .ADDR_WIDTH(BRAM_ADDR_WIDTH)
  ) bram_controller_i (
      .clk(clk),
      .rst_p(rst_p),
      .rea_p(bram_rea_p),
      .wea_p(bram_wea_p),
      .ack_p(bram_ack_p),
      .bram_addr_r(bram_addr_r),
      .bram_addr_w(bram_addr_w),
      .bram_data_w(bram_data_w),
      .bram_data_r(bram_data_r)
  );

  // FIXME: Static Forward Table
  reg [2:0] fwt_counter;
  always_ff @(posedge clk) begin
    if (rst_p) begin
      bram_wea_p  <= 0;
      bram_addr_w <= 0;
      bram_data_w <= 0;
      fwt_counter <= 0;
    end else begin
      if (fwt_counter < 4) begin
        if (bram_ack_p) begin
          fwt_counter <= fwt_counter + 1;
          bram_wea_p  <= 0;
          bram_addr_w <= 0;
          bram_data_w <= 0;
        end else begin
          bram_wea_p <= 1;
          case (fwt_counter)
            3'd0: begin
              bram_addr_w <= 5'd0;
              bram_data_w <= {
                0,  // padding
                1'b1,  // valid
                8'd128,  // prefix length
                128'h041069feff641f8e00000000000080fe,  // next hop
                128'h041069feff641f8e00000000000080fe  // prefix
              };
            end
            3'd1: begin
              bram_addr_w <= 5'd1;
              bram_data_w <= {
                0,  // padding
                1'b1,  // valid
                8'd128,  // prefix length
                128'h011069feff641f8e00000000000080fe,  // next hop
                128'h011069feff641f8e00000000000080fe  // prefix
              };
            end
            3'd2: begin
              bram_addr_w <= 5'd2;
              bram_data_w <= {
                0,  // padding
                1'b0,  // valid
                8'd16,  // prefix length
                128'h000000000000000000000000000080FF,  // next hop
                128'h000000000000000000000000000080FF  // prefix
              };
            end
            3'd3: begin
              bram_addr_w <= 5'd3;
              bram_data_w <= {
                0,  // padding
                1'b0,  // valid
                8'd16,  // prefix length
                128'h000000000000000000000000000080FF,  // next hop
                128'h000000000000000000000000000080FF  // prefix
              };
            end
            default: begin
              bram_addr_w <= 0;
              bram_data_w <= 0;
            end
          endcase
        end
      end
    end
  end


  // =============================================================
  //  Forward Table
  // =============================================================

  reg fwt_ea_p;
  reg [127:0] fwt_next_hop_addr;
  reg fwt_ack_p;
  reg fwt_exists;

  forward_table #(
      .BASE_ADDR (2'h0),
      .MAX_ADDR  (2'h3),
      .DATA_WIDTH(BRAM_DATA_WIDTH),
      .ADDR_WIDTH(BRAM_ADDR_WIDTH)
  ) ftb_test (
      .clk(clk),
      .rst_p(rst_p),
      .ea_p(fwt_ea_p),
      .ip6_addr(first_beat.data.ip6.dst),
      .next_hop_addr(fwt_next_hop_addr),
      .ack_p(fwt_ack_p),
      .exists(fwt_exists),
      .mem_data(bram_data_r),
      .mem_ack_p(bram_ack_p),
      .mem_addr(bram_addr_r),
      .mem_rea_p(bram_rea_p)
  );

  always_ff @(posedge clk) begin
    if (rst_p) begin
      fwt_ea_p <= 1'b0;
    end else begin
      if (fw_state == FW_FWT) begin
        fwt_ea_p <= 1'b1;
      end else begin
        fwt_ea_p <= 1'b0;
      end
    end
  end

  // =============================================================
  //  ND cache signals definition
  // =============================================================

  logic [127:0] neighbor_ip6_addr;
  logic [ 47:0] neighbor_mac_addr;
  logic [  1:0] neighbor_iface;
  logic         cache_write_valid;  // Set to 1'b1 on finding an NS/NA packet valid
  logic         cache_update_ea_p;
  logic         cache_write_ea_p;
  logic         cache_read_ea_p;
  logic [ 47:0] cache_mac_addr_o;  // Address read from cache
  logic [  1:0] cache_iface_o;  // Interface read from cache
  logic         cache_exists;
  logic         cache_ready;
  logic         cache_read_ready;

  neighbor_cache neighbor_cache_i (
      .clk            (clk),
      .rst_p          (rst_p),
      .IPv6_addr      (neighbor_ip6_addr),
      .w_MAC_addr     (neighbor_mac_addr),
      .w_port_id      (neighbor_iface),
      .r_MAC_addr     (cache_mac_addr_o),
      .r_port_id      (cache_iface_o),
      .uea_p          (cache_update_ea_p),
      .wea_p          (cache_write_ea_p),
      .rea_p          (cache_read_ea_p),
      .exists         (cache_exists),
      .ready          (cache_ready),
      .nud_probe      (nud_we_p),
      .probe_IPv6_addr(nud_exp_addr),
      .probe_port_id  (nud_iface)
  );

  always_ff @(posedge clk) begin
    if (rst_p) begin
      neighbor_ip6_addr <= 128'b0;
      neighbor_mac_addr <= 48 'b0;
      neighbor_iface    <= 2  'b0;
      cache_update_ea_p <= 1  'b0;
      cache_write_ea_p  <= 1  'b0;
      cache_read_ea_p   <= 1  'b0;
      cache_write_valid <= 1  'b0;
      cache_read_ready  <= 1  'b0;
    end else begin
      if ((state == DP_NS) && (ns_state == NS_CHECKSUM_NS)) begin
        neighbor_ip6_addr <= ns_packet_i.ether.ip6.src;
        neighbor_mac_addr <= ns_packet_i.option.mac_addr;
        neighbor_iface    <= in_meta_src;
      end else if ((state == DP_NA) && (na_state == NA_CHECKSUM)) begin
        neighbor_ip6_addr <= na_packet_i.ether.ip6.src;
        neighbor_mac_addr <= na_packet_i.option.mac_addr;
        neighbor_iface    <= in_meta_src;
      end else begin
        case (cache_state)
          CACHE_SLEEP: begin
            cache_update_ea_p <= 1'b0;
            cache_write_ea_p  <= 1'b0;
            cache_read_ea_p   <= 1'b0;
            cache_read_ready  <= 1'b0;
            if ((state == DP_NS) && (ns_state == NS_SEND_1)) begin
              cache_write_valid <= ns_valid;
            end else if ((state == DP_NA) && (na_state == NA_CACHE)) begin
              cache_write_valid <= na_valid;
            end
          end
          CACHE_REQUIRE_UPDATE: begin
            if (cache_ready) begin
              cache_update_ea_p <= 1'b0;
              cache_write_ea_p  <= 1'b1;
              cache_read_ea_p   <= 1'b0;
            end else begin
              cache_update_ea_p <= 1'b0;
              cache_write_ea_p  <= 1'b0;
              cache_read_ea_p   <= 1'b0;
            end
          end
          CACHE_SIGNAL_SENT: begin
            cache_update_ea_p <= 1'b0;
            cache_write_ea_p  <= 1'b1;
            cache_read_ea_p   <= 1'b0;
            cache_write_valid <= 1'b0;  // Reset for it's done
          end
          CACHE_READ: begin
            if ((state == DP_FWD) && (fw_state == FW_NC)) begin
              neighbor_ip6_addr <= fwt_next_hop_addr;  // Next hop from Forward Table
            end
            cache_update_ea_p <= 1'b0;
            cache_write_ea_p  <= 1'b0;
            cache_read_ea_p   <= 1'b1;
            cache_write_valid <= 1'b0;
            cache_read_ready  <= 1'b0;
          end
          CACHE_READ_DONE: begin
            cache_read_ready <= 1'b1;
          end
          default: begin
            cache_update_ea_p <= 1'b0;
            cache_write_ea_p  <= 1'b0;
            cache_read_ea_p   <= 1'b0;
            cache_read_ready  <= 1'b0;
          end
        endcase
      end
    end
  end

  // =============================================================
  //  out pack construction
  // =============================================================

  always_ff @(posedge clk) begin
    if (rst_p) begin
      out <= 0;
    end else begin
      if ((state == DP_NS) && (ns_state == NS_WAIT)) begin  // Construct the first pack of NA
        out.data            <= ns_na_packet_i[447:0];  // 56 bytes
        out.is_first        <= 1'b1;
        out.last            <= 1'b0;  // Not the last pack
        out.valid           <= 1'b0;  // Wait for ND_SEND_1 to send
        out.keep            <= 56'hffffffffffffff;  // Full pack
        out.meta.dont_touch <= 1'b0;
        out.meta.drop_next  <= 1'b0;
        out.meta.dest       <= in_meta_src;
      end else if ((state == DP_NS) && (ns_state == NS_SEND_1)) begin
        out.valid     <= 1'b1;
        out.meta.drop <= !ns_valid;
      end else if ((state == DP_NS) && (ns_state == NS_SEND_2)) begin
        out.data <= {208'h0, ns_na_packet_i[687:448]};  // 86 - 56 = 30 bytes
        out.data[15:0] <= ~{ns_na_checksum[7:0], ns_na_checksum[15:8]};
        out.is_first <= 1'b0;
        out.last <= 1'b1;  // The last pack
        out.valid <= 1'b1;  // Send directly
        out.keep            <= 56'h0000003fffffff;                // 30 bytes valid: 0b...11_1111_1111_1111_1111_1111_1111_1111
        out.meta.drop <= 1'b0;
        out.meta.dont_touch <= 1'b0;
        out.meta.drop_next <= 1'b0;
        out.meta.dest <= in_meta_src;
      end else if ((state == DP_NUD) && (nud_state == NUD_SEND_1)) begin
        out.data            <= nud_ns[447:0];
        out.is_first        <= 1'b1;
        out.last            <= 1'b0;
        out.valid           <= 1'b1;
        out.keep            <= 56'hffffffffffffff;
        out.meta.drop       <= 1'b0;
        out.meta.dont_touch <= 1'b0;
        out.meta.drop_next  <= 1'b0;
        out.meta.dest       <= nud_iface_o;
      end else if ((state == DP_NUD) && (nud_state == NUD_SEND_2)) begin
        out.data            <= {208'h0, nud_ns[687:448]};
        out.data[15:0]      <= ~{nud_checksum[7:0], nud_checksum[15:8]};
        out.is_first        <= 1'b0;
        out.last            <= 1'b1;
        out.valid           <= 1'b1;
        out.keep            <= 56'h0000003fffffff;
        out.meta.drop       <= 1'b0;
        out.meta.dont_touch <= 1'b0;
        out.meta.drop_next  <= 1'b0;
        out.meta.dest       <= nud_iface_o;
      end else if (state == DP_FWD) begin
        if (fw_state == FW_NC) begin
          if (cache_exists && cache_ready) begin
            // Send first pack
            out.valid                <= 1'b1;
            // Construct IPv6 header
            out.data.ip6.p           <= first_beat.data.ip6.p;
            out.data.ip6.dst         <= first_beat.data.ip6.dst;
            out.data.ip6.src         <= first_beat.data.ip6.src;
            out.data.ip6.hop_limit   <= first_beat.data.ip6.hop_limit - 1;
            out.data.ip6.next_hdr    <= first_beat.data.ip6.next_hdr;
            out.data.ip6.payload_len <= first_beat.data.ip6.payload_len;
            out.data.ip6.flow_lo     <= first_beat.data.ip6.flow_lo;
            out.data.ip6.version     <= first_beat.data.ip6.version;
            out.data.ip6.flow_hi     <= first_beat.data.ip6.flow_hi;
            // Construct Ether header
            out.data.ethertype       <= first_beat.data.ethertype;
            out.data.dst             <= cache_mac_addr_o;
            case (cache_iface_o)
              2'd0: out.data.src <= mac_addrs[0];
              2'd1: out.data.src <= mac_addrs[1];
              2'd2: out.data.src <= mac_addrs[2];
              2'd3: out.data.src <= mac_addrs[3];
              default: out.data.src <= 48'h0;
            endcase
            // Meta data
            out.is_first        <= first_beat.is_first;
            out.last            <= first_beat.last;
            out.keep            <= first_beat.keep;
            out.meta.dest       <= cache_iface_o;
            out.meta.dont_touch <= first_beat.meta.dont_touch;
            out.meta.drop_next  <= first_beat.meta.drop_next;
            out.meta.drop       <= first_beat.meta.drop;
          end
        end else if (fw_state == FW_FW) begin
          if (out_ready && in.valid) begin
            // Send the rest of the packs
            out.valid           <= 1'b1;
            // Inherit the data from the input
            out.data            <= in.data;
            // Mata data
            out.is_first        <= in.is_first;
            out.last            <= in.last;
            out.keep            <= in.keep;
            out.meta.dest       <= cache_iface_o;
            out.meta.dont_touch <= in.meta.dont_touch;
            out.meta.drop_next  <= in.meta.drop_next;
            out.meta.drop       <= in.meta.drop;
          end else if (!out_ready) begin
            out.valid <= 1'b0;
          end
        end else if (fw_state == FW_SEND_1) begin
          if (!out_ready) begin
            out.valid <= 1'b0;
          end
        end else if (fw_state == FW_SEND_F) begin
          if (!out_ready) begin
            out.valid <= 1'b0;
          end
        end else if (fw_state == FW_DONE) begin
          if (!out_ready) begin
            out.valid <= 1'b0;
          end
        end else begin
          out.valid <= 1'b0;
        end
      end else begin
        out.valid <= 1'b0;
      end
    end
  end

  // =============================================================
  //  ND cache state transition
  // =============================================================

  always_comb begin
    cache_next_state = CACHE_SLEEP;
    case (cache_state)
      CACHE_SLEEP: begin
        if (
          cache_write_valid && (
                       ((state == DP_NS) && (ns_state == NS_CHECKSUM_NA))
                    || ((state == DP_NA) && (na_state == NA_CACHE      ))
                )
        ) begin
          cache_next_state = CACHE_REQUIRE_UPDATE;
        end else if ((state == DP_FWD) && (fw_state == FW_NC)) begin
          cache_next_state = CACHE_READ;
        end
      end
      CACHE_REQUIRE_UPDATE: begin
        cache_next_state = (cache_write_ea_p) ? CACHE_SIGNAL_SENT : CACHE_REQUIRE_UPDATE;
      end
      CACHE_SIGNAL_SENT: begin
        cache_next_state = (cache_ready) ? CACHE_SLEEP : CACHE_SIGNAL_SENT;
      end
      CACHE_READ: begin
        cache_next_state = CACHE_READ_DONE;
      end
      CACHE_READ_DONE: begin
        cache_next_state = CACHE_SLEEP;
      end
      default: begin
        cache_next_state = CACHE_SLEEP;
      end
    endcase
  end

  // =============================================================
  //  NS state transition
  // =============================================================

  always_comb begin
    case (ns_state)
      NS_IDLE: begin
        // ns_next_state = ((state == DP_IDLE) && (next_state == DP_NS)) ? NS_WAIT : NS_IDLE;
        ns_next_state = ((state_reg == DP_IDLE) && (next_state_reg == DP_NS)) ? NS_WAIT : NS_IDLE;
      end
      NS_WAIT: begin
        ns_next_state = (s_ready) ? NS_CHECKSUM_NS : NS_WAIT;
      end
      NS_CHECKSUM_NS: begin
        ns_next_state = (ns_checksum_valid) ? NS_SEND_1 : NS_CHECKSUM_NS; // Even if checksum is wrong
      end
      NS_SEND_1: begin
        ns_next_state = (out_ready) ? NS_CHECKSUM_NA : NS_SEND_1;
      end
      NS_CHECKSUM_NA: begin
        ns_next_state = (ns_na_checksum_valid) ? NS_SEND_2 : NS_CHECKSUM_NA;
      end
      NS_SEND_2: begin
        ns_next_state = (out_ready) ? NS_IDLE : NS_SEND_2;
      end
      default: begin
        ns_next_state = NS_IDLE;
      end
    endcase
  end

  // =============================================================
  //  NA state transition
  // =============================================================

  always_comb begin
    case (na_state)
      NA_IDLE: begin
        // na_next_state = ((state == DP_IDLE) && (next_state == DP_NA)) ? NA_WAIT : NA_IDLE;
        na_next_state = ((state_reg == DP_IDLE) && (next_state_reg == DP_NA)) ? NA_WAIT : NA_IDLE;
      end
      NA_WAIT: begin
        na_next_state = (s_ready) ? NA_CHECKSUM : NA_WAIT;
      end
      NA_CHECKSUM: begin
        na_next_state = (na_checksum_valid) ? NA_CACHE : NA_CHECKSUM;
      end
      NA_CACHE: begin
        na_next_state = NA_IDLE;
      end
      default: begin
        na_next_state = NA_IDLE;
      end
    endcase
  end

  // =============================================================
  //  NUD state transition
  // =============================================================

  always_comb begin
    case (nud_state)
      NUD_IDLE: begin
        // nud_next_state = ((state == DP_IDLE) && (next_state == DP_NUD)) ? NUD_SEND_1 : NUD_IDLE;
        nud_next_state = ((state_reg == DP_IDLE) && (next_state_reg == DP_NUD)) ? NUD_SEND_1 : NUD_IDLE;
      end
      NUD_SEND_1: begin
        nud_next_state = (out_ready) ? NUD_WAIT : NUD_SEND_1;
      end
      NUD_WAIT: begin
        nud_next_state = (nud_ns_valid) ? NUD_SEND_2 : NUD_WAIT;
      end
      NUD_SEND_2: begin
        nud_next_state = (out_ready) ? NUD_IDLE : NUD_SEND_2;
      end
      default: begin
        nud_next_state = NUD_IDLE;
      end
    endcase
  end

  // =============================================================
  //  Forward state transition
  // =============================================================
  always_comb begin
    fw_next_state = FW_IDLE;
    case (fw_state)
      FW_IDLE: begin
        if (state == DP_FWD) fw_next_state = FW_FWT;
      end
      FW_FWT: begin
        if (fwt_ack_p) begin
          if (fwt_exists) begin
            fw_next_state = FW_NC;
          end else begin
            fw_next_state = FW_DONE;
          end
        end else begin
          fw_next_state = FW_FWT;
        end
      end
      FW_NC: begin
        if (cache_read_ready) begin
          if (cache_exists) begin
            if (first_beat.last) begin
              fw_next_state = FW_DONE;
            end else begin
              fw_next_state = FW_SEND_1;
            end
          end else begin
            fw_next_state = FW_DONE;
          end
        end else begin
          fw_next_state = FW_NC;
        end
      end
      FW_FW: begin
        if (out_ready && in.valid) begin
          if (in.last) begin
            fw_next_state = FW_DONE;
          end else begin
            fw_next_state = FW_SEND_F;
          end
        end else begin
          fw_next_state = FW_FW;
        end
      end
      FW_SEND_1: begin
        fw_next_state = FW_FW;
      end
      FW_SEND_F: begin
        fw_next_state = FW_FW;
      end
      FW_DONE: begin
        if (out_ready) begin
          fw_next_state = FW_IDLE;
        end
      end
      default: fw_next_state = FW_IDLE;
    endcase

  end

  // =============================================================
  //  Top level state transition
  // =============================================================

  always_comb begin
    case (state)
      DP_IDLE: begin
        if (!s_ready || !in.is_first) begin
          next_state = (nud_ns_valid) ? DP_NUD : DP_IDLE;
        end else begin
          if (
                           (in.data.ip6.next_hdr == IP6_HDR_TYPE_ICMPv6)
                        && (in.data.ip6.p[7:0] == ICMPv6_HDR_TYPE_NS)
                        && (in.data.ip6.hop_limit == IP6_HDR_HOP_LIMIT_DEFAULT)
                        && (in.data.ip6.p[15:8] == 0)
                        && ({in.data.ip6.payload_len[7:0], in.data.ip6.payload_len[15:8]} >= 16'd24)
                        && (in.data.ip6.payload_len[10:8] == 3'b000)
                        && (in.data.ip6.src != 0)
                    ) begin
            next_state = DP_NS;
          end else if (
                           (in.data.ip6.next_hdr == IP6_HDR_TYPE_ICMPv6)
                        && (in.data.ip6.p[7:0] == ICMPv6_HDR_TYPE_NA)
                        && (in.data.ip6.hop_limit == IP6_HDR_HOP_LIMIT_DEFAULT)
                        && (in.data.ip6.p[15:8] == 0)
                        && ({in.data.ip6.payload_len[7:0], in.data.ip6.payload_len[15:8]} >= 16'd24)
                        && (in.data.ip6.payload_len[10:8] == 3'b000)
                        && (in.data.ip6.src != 0)
                    ) begin
            next_state = DP_NA;
          end else if ((in.data.ip6.version == 6) && (in.data.ip6.hop_limit > 1)) begin
            next_state = DP_FWD;
          end else begin
            next_state = DP_IDLE;
          end
        end
      end
      DP_NS: begin
        next_state = ((ns_state_reg != NS_IDLE) && (ns_next_state_reg == NS_IDLE)) ? DP_IDLE : DP_NS;
      end
      DP_NA: begin
        next_state = ((na_state_reg != NA_IDLE) && (na_next_state_reg == NA_IDLE)) ? DP_IDLE : DP_NA;
      end
      DP_NUD: begin
        next_state = ((nud_state_reg != NUD_IDLE) && (nud_next_state_reg == NUD_IDLE)) ? DP_IDLE : DP_NUD;
      end
      DP_FWD: begin
        next_state = ((fw_state != FW_IDLE) && (fw_next_state == FW_IDLE)) ? DP_IDLE : DP_FWD;
      end
      default: begin
        next_state = DP_IDLE;
      end
    endcase
  end

endmodule : datapath_sm
