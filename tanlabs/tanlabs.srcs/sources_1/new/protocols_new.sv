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
  // Forward Logic Global Signals Definition
  // =============================================================
  logic fw_in_ready;
  logic fw_reset;
  logic cache_read_ready;
  assign fw_reset = (state != DP_FWD && next_state != DP_FWD);


  // =============================================================
  //  Top level util-signals definition
  // =============================================================

  assign in_ready = (
           ((state == DP_IDLE) && (next_state != DP_NUD ) && (next_state != DP_FWD))
        || ((state == DP_NS  ) && (ns_state   == NS_WAIT))
        || ((state == DP_NA  ) && (na_state   == NA_WAIT))
        || ((state == DP_FWD) && fw_in_ready)
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
      if (
           ((state == DP_IDLE) && (next_state != DP_IDLE) && (next_state != DP_NUD))
           || ((state == DP_FWD) && (in.is_first))
         ) begin
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

  fw_frame_beat_t fwt_in_beat;
  fw_frame_beat_t fwt_out_beat;
  reg fwt_out_ready;
  reg fwt_in_ready;
  reg fwt_exists;
  reg fwt_ip6_addr;

  forward_table #(
      .BASE_ADDR (2'h0),
      .MAX_ADDR  (2'h3),
      .DATA_WIDTH(BRAM_DATA_WIDTH),
      .ADDR_WIDTH(BRAM_ADDR_WIDTH)
  ) ftb_test (
      .clk(clk),
      .rst_p(rst_p || fw_reset),
      .in_beat(fwt_in_beat),
      .out_beat(fwt_out_beat),
      .in_ready(fwt_in_ready),
      .out_ready(fwt_out_ready),
      .exists(fwt_exists),
      .mem_data(bram_data_r),
      .mem_ack_p(bram_ack_p),
      .mem_addr(bram_addr_r),
      .mem_rea_p(bram_rea_p)
  );

  // =============================================================
  //  Forward logic pipline
  // =============================================================
  logic fw_first_beat_in_ready;
  logic fw_following_beat_in_ready;
  logic fw_out_beat_in_ready;

  // ================
  // Judge input type
  // ================
  typedef enum logic [2:0] {
    FW_TYPE_NS,
    FW_TYPE_NA,
    FW_TYPE_IPV6,
    FW_TYPE_OTHERS
  } fw_in_type_t;
  fw_in_type_t fw_in_type;
  always_comb begin : FW_InputType
    fw_in_type = FW_TYPE_OTHERS;
    if (`should_handle(in)) begin
      if (in.data.ip6.version == 6) begin
        if (
                 (in.data.ip6.next_hdr == IP6_HDR_TYPE_ICMPv6)
              && (in.data.ip6.p[7:0] == ICMPv6_HDR_TYPE_NS)
              && (in.data.ip6.hop_limit == IP6_HDR_HOP_LIMIT_DEFAULT)
              && (in.data.ip6.p[15:8] == 0)
              && ({in.data.ip6.payload_len[7:0], in.data.ip6.payload_len[15:8]} >= 16'd24)
              && (in.data.ip6.payload_len[10:8] == 3'b000)
              && (in.data.ip6.src != 0)
          ) begin
          fw_in_type = FW_TYPE_NS;
        end else if(
                 (in.data.ip6.next_hdr == IP6_HDR_TYPE_ICMPv6)
              && (in.data.ip6.p[7:0] == ICMPv6_HDR_TYPE_NA)
              && (in.data.ip6.hop_limit == IP6_HDR_HOP_LIMIT_DEFAULT)
              && (in.data.ip6.p[15:8] == 0)
              && ({in.data.ip6.payload_len[7:0], in.data.ip6.payload_len[15:8]} >= 16'd24)
              && (in.data.ip6.payload_len[10:8] == 3'b000)
              && (in.data.ip6.src != 0)
          ) begin
          fw_in_type = FW_TYPE_NA;
        end else if (in.data.ip6.hop_limit > 1) begin
          fw_in_type = FW_TYPE_IPV6;
        end else begin  // Invalid Hop Limit. Drop it.
          fw_in_type = FW_TYPE_OTHERS;
        end
      end
    end
  end


  // =================
  // Input selector
  // =================
  fw_frame_beat_t       fw_in_first_beat;
  fw_frame_beat_t       fw_in_following_beat;
  reg             [4:0] fw_in_counter;  // 0 is reserved for a bubble
  reg                   fw_in_should_stop;
  dp_state_t            fw_out_state;
  assign fw_in_ready =  !fw_in_should_stop &&
                        (
                          (fw_first_beat_in_ready && in.is_first) ||
                          (fw_following_beat_in_ready && !in.is_first)
                        );
  always_ff @(posedge clk) begin : FW_InputSelector
    if (rst_p || fw_reset) begin
      fw_in_first_beat     <= 0;
      fw_in_following_beat <= 0;
      fw_in_counter        <= 0;
      fw_in_should_stop    <= 1;
      fw_out_state         <= DP_IDLE;
    end else begin
      if (state == DP_IDLE && next_state == DP_FWD) begin
        fw_in_should_stop <= 0;
      end else begin
        if (fw_first_beat_in_ready) begin
          if (fw_in_should_stop) begin
            fw_in_first_beat.valid   <= 1;
            fw_in_first_beat.stop    <= 1;
            fw_in_first_beat.waiting <= 0;
            fw_in_first_beat.error   <= ERR_NONE;
          end else begin
            if (`should_handle(in)) begin
              // Set Data
              fw_in_first_beat.data <= in;
              // Set Index
              if (fw_in_counter == 5'b11111) begin
                fw_in_counter          <= 1;
                fw_in_first_beat.index <= 1;
              end else begin
                fw_in_counter          <= fw_in_counter + 1;
                fw_in_first_beat.index <= fw_in_counter + 1;
              end
              // Set Valid
              fw_in_first_beat.valid <= 1;
              // Set Other Signals
              case (fw_in_type)
                FW_TYPE_IPV6: begin
                  // Process the first beat
                  fw_in_should_stop        <= 0;
                  fw_in_first_beat.waiting <= 1;
                  fw_in_first_beat.stop    <= 0;
                  fw_in_first_beat.error   <= ERR_NONE;
                  fw_out_state             <= DP_IDLE;
                end
                FW_TYPE_NS: begin
                  // Stop Forward Logic
                  fw_in_should_stop        <= 1;
                  fw_in_first_beat.waiting <= 0;
                  fw_in_first_beat.stop    <= 1;
                  fw_in_first_beat.error   <= ERR_WRONG_TYPE;
                  fw_out_state             <= DP_NS;
                end
                FW_TYPE_NA: begin
                  // Stop Forward Logic
                  fw_in_should_stop        <= 1;
                  fw_in_first_beat.waiting <= 0;
                  fw_in_first_beat.stop    <= 1;
                  fw_in_first_beat.error   <= ERR_WRONG_TYPE;
                  fw_out_state             <= DP_NA;
                end
                default: begin
                  fw_in_first_beat.waiting <= 1;
                  fw_in_first_beat.stop    <= 0;
                  fw_in_first_beat.error   <= ERR_WRONG_TYPE;
                  fw_out_state             <= DP_IDLE;
                end
              endcase
            end else begin  // Should not handle
              fw_in_first_beat.valid   <= 0;
              fw_in_first_beat.waiting <= 0;
              fw_in_first_beat.stop    <= 0;
              fw_in_first_beat.error   <= ERR_NONE;
            end
          end
        end
        if (fw_following_beat_in_ready) begin
          fw_in_following_beat.index     <= fw_in_counter;
          if (fw_in_should_stop) begin
            fw_in_following_beat.valid   <= 1;
            fw_in_following_beat.waiting <= 0;
            fw_in_following_beat.stop    <= 1;
            fw_in_following_beat.error   <= ERR_NONE;
          end else begin
            if (`should_handle_following(in)) begin
              // Pass the following beats
              fw_in_following_beat.data    <= in;
              fw_in_following_beat.valid   <= 1;
              fw_in_following_beat.waiting <= 1;
              fw_in_following_beat.stop    <= 0;
              fw_in_following_beat.error   <= ERR_NONE;
            end else begin
              fw_in_following_beat.valid   <= 0;
              fw_in_following_beat.waiting <= 0;
              fw_in_following_beat.stop    <= 0;
              fw_in_following_beat.error   <= ERR_NONE;
            end
          end
        end
      end
    end
  end

  // =================
  // Process First Beat
  // =================

  // Forward Table Input
  assign fw_first_beat_in_ready = fwt_in_ready || !fw_in_first_beat.valid;
  assign fwt_in_beat            = fw_in_first_beat;

  // Neighbor Cache
  logic nc_in_ready;
  assign fwt_out_ready = nc_in_ready;

  logic           nc_out_ready;
  fw_frame_beat_t nc_out_beat;
  assign nc_in_ready = (nc_out_ready || !nc_out_beat.valid) && cache_read_ready;


  logic fw_out_first_beat_in_ready;
  assign nc_out_ready = fw_out_first_beat_in_ready;

  // =================
  // Process Following Beat
  // =================

  // FIXME: Customize the delay
  // Toy Example: 3 beats delay
  // Beat 1 (= fw_in_following_beat)
  fw_frame_beat_t fw_follow_1;
  logic           fw_follow_1_in_ready;
  assign fw_follow_1                = fw_in_following_beat;
  assign fw_following_beat_in_ready = fw_follow_1_in_ready;

  // Beat 2
  fw_frame_beat_t fw_follow_2;
  logic           fw_follow_2_in_ready;
  assign fw_follow_1_in_ready = fw_follow_2_in_ready || !fw_follow_1.valid;
  always_ff @(posedge clk) begin : FW_FollowingBeat_2
    if (rst_p || fw_reset) begin
      fw_follow_2 <= 0;
    end else begin
      if (fw_follow_2_in_ready) begin
        fw_follow_2 <= fw_follow_1;
      end
    end
  end

  // Beat 3
  fw_frame_beat_t fw_follow_3;
  logic           fw_follow_3_in_ready;
  assign fw_follow_2_in_ready = fw_follow_3_in_ready || !fw_follow_2.valid;
  always_ff @(posedge clk) begin : FW_FollowingBeat_3
    if (rst_p || fw_reset) begin
      fw_follow_3 <= 0;
    end else begin
      if (fw_follow_3_in_ready) begin
        fw_follow_3 <= fw_follow_2;
      end
    end
  end

  logic fw_out_following_beat_in_ready;
  assign fw_follow_3_in_ready = fw_out_following_beat_in_ready;

  // =================
  // Output Selector
  // =================
  // State Machine
  typedef enum logic [2:0] {
    FWO_IDLE,
    FWO_SELECT,
    FWO_SEND_1,
    FWO_SEND_F,
    FWO_DONE
  } fwo_state_t;
  fwo_state_t fwo_state;

  // Variable Rename
  fw_frame_beat_t fw_out_first_beat;
  fw_frame_beat_t fw_out_following_beat;
  assign fw_out_beat_in_ready = fw_out_first_beat_in_ready || fw_out_following_beat_in_ready;

  // Counter : 31 Max
  localparam UPPER_LIMIT = 5'd25;
  localparam LOWER_LIMIT = 5'd6;
  logic fw_first_beat_should_send;  // Whether the first beat should be sent
  assign fw_first_beat_should_send = (!fw_out_following_beat.valid) ||
                                     (fw_out_following_beat.valid &&
                                      (
                                          (
                                            (fw_out_first_beat.index < LOWER_LIMIT) &&
                                            (fw_out_following_beat.index < UPPER_LIMIT) &&
                                            (fw_out_first_beat.index < fw_out_following_beat.index)
                                          ) ||
                                          (
                                            (fw_out_first_beat.index >= LOWER_LIMIT) &&
                                            (fw_out_first_beat.index < UPPER_LIMIT) &&
                                            (fw_out_first_beat.index < fw_out_following_beat.index)
                                          ) ||
                                          (
                                            (fw_out_first_beat.index >= UPPER_LIMIT) &&
                                            (fw_out_following_beat.index >= LOWER_LIMIT) &&
                                            (fw_out_first_beat.index < fw_out_following_beat.index)
                                          ) ||
                                          (
                                            (fw_out_first_beat.index >= UPPER_LIMIT) &&
                                            (fw_out_following_beat.index < LOWER_LIMIT)
                                          ) ||
                                          (
                                            (fw_out_first_beat.index == fw_out_following_beat.index) &&
                                            (fw_out_first_beat.waiting)
                                            // Not Waiting Implies the first beat has been sent
                                          )
                                        )
                                     );

  // Interface
  logic [1:0] fw_out_port;

  // Out Ready Signal
  assign fw_out_first_beat_in_ready    = (fwo_state == FWO_IDLE) &&
                                      (
                                        (!fw_out_first_beat.valid) ||
                                        (fw_out_first_beat.valid && !fw_out_first_beat.waiting)
                                      );
  assign fw_out_following_beat_in_ready = (fwo_state == FWO_IDLE) &&
                                      (
                                        (!fw_out_following_beat.valid) ||
                                        (fw_out_following_beat.valid && !fw_out_following_beat.waiting)
                                      );

  // Should send signal
  logic fw_should_send;
  assign fw_should_send     = out_ready && (
                                              (
                                                   fw_out_first_beat.waiting
                                                && fw_out_first_beat.valid
                                                && fw_first_beat_should_send
                                              ) ||
                                              (
                                                  fw_out_following_beat.waiting
                                               && fw_out_following_beat.valid
                                               && !fw_first_beat_should_send
                                              )
                                            );
  logic fw_out_should_stop;
  assign fw_out_should_stop = fw_out_first_beat.stop && fw_out_following_beat.stop;

  // Logic
  always_ff @(posedge clk) begin : FW_OutputSelector
    if (rst_p || fw_reset) begin
      // state machine
      fwo_state             <= FWO_IDLE;
      // Interface
      fw_out_port           <= 0;
      // Out beat
      fw_out_first_beat     <= 0;
      fw_out_following_beat <= 0;
    end else begin
      case (fwo_state)
        FWO_IDLE: begin
          // Save the first beat
          if (fw_out_first_beat_in_ready) begin
            // FW Signals
            fw_out_first_beat.valid                <= nc_out_beat.valid;
            fw_out_first_beat.stop                 <= nc_out_beat.stop;
            fw_out_first_beat.index                <= nc_out_beat.index;
            fw_out_first_beat.error                <= nc_out_beat.error;
            if (fw_out_first_beat.index != nc_out_beat.index) begin
              fw_out_first_beat.waiting            <= nc_out_beat.waiting;
            end
            // FW Data
            fw_out_first_beat.data.data            <= nc_out_beat.data.data;
            fw_out_first_beat.data.keep            <= nc_out_beat.data.keep;
            fw_out_first_beat.data.last            <= nc_out_beat.data.last;
            fw_out_first_beat.data.user            <= nc_out_beat.data.user;
            fw_out_first_beat.data.valid           <= nc_out_beat.data.valid;
            fw_out_first_beat.data.is_first        <= nc_out_beat.data.is_first;
            // Meta
            fw_out_first_beat.data.meta.id         <= nc_out_beat.data.meta.id;
            fw_out_first_beat.data.meta.dest       <= nc_out_beat.data.meta.dest;
            fw_out_first_beat.data.meta.dont_touch <= nc_out_beat.data.meta.dont_touch;
            fw_out_first_beat.data.meta.drop_next  <= nc_out_beat.data.meta.drop_next;
            // Check its error. And set drop signal
            case (nc_out_beat.error)
              ERR_NONE: begin
                fw_out_first_beat.data.meta.drop <= 0;
              end
              ERR_FWT_MISS: begin
                fw_out_first_beat.data.meta.drop <= 1;
              end
              ERR_NC_MISS: begin
                fw_out_first_beat.data.meta.drop <= 1;
              end
              ERR_WRONG_TYPE: begin
                fw_out_first_beat.data.meta.drop <= 1;
              end
              default: begin
                fw_out_first_beat.data.meta.drop <= 1;
              end
            endcase
          end
          // Save the following beat
          if (fw_out_following_beat_in_ready) begin
            fw_out_following_beat <= fw_follow_3;
          end
          // If there is a packet to send, transfer to FWO_SELECT
          if (fw_should_send && !fw_out_should_stop) begin
            fwo_state <= FWO_SELECT;
          end
        end
        FWO_SELECT: begin
          if (fw_first_beat_should_send) begin
            if (fw_out_first_beat.valid && !fw_out_first_beat.stop) begin
              // Not an empty beat. Not a stop beat
              fwo_state   <= FWO_SEND_1;
              fw_out_port <= fw_out_first_beat.data.meta.dest;
            end else begin
              // Empty first beat or stop first beat
              fw_out_first_beat.waiting <= 0;
              fwo_state                 <= FWO_IDLE;
            end
          end else begin
            if (fw_out_following_beat.valid && !fw_out_following_beat.stop) begin
              fwo_state <= FWO_SEND_F;
            end else begin
              // Empty following beat, drop it
              fwo_state                     <= FWO_IDLE;
              fw_out_following_beat.waiting <= 0;
            end
          end
        end
        FWO_SEND_1: begin
          fw_out_first_beat.waiting <= 0;
          fwo_state                 <= FWO_DONE;
        end
        FWO_SEND_F: begin
          fw_out_following_beat.waiting <= 0;
          fwo_state                     <= FWO_DONE;
        end
        FWO_DONE: begin
          fwo_state <= FWO_IDLE;
        end
        default: begin
          fwo_state <= FWO_IDLE;
        end
      endcase
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
      neighbor_mac_addr <= 48'b0;
      neighbor_iface    <= 2'b0;
      cache_update_ea_p <= 1'b0;
      cache_write_ea_p  <= 1'b0;
      cache_read_ea_p   <= 1'b0;
      cache_write_valid <= 1'b0;
      cache_read_ready  <= 1'b1;
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
            if (cache_next_state == CACHE_READ) begin
              cache_read_ready <= 1'b0;
            end
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
            if (state == DP_FWD) begin
              // Next hop from Forward Table
              neighbor_ip6_addr <= nc_out_beat.data.data.ip6.dst;
            end
            cache_update_ea_p <= 1'b0;
            cache_write_ea_p  <= 1'b0;
            cache_read_ea_p   <= 1'b1;
            cache_write_valid <= 1'b0;
          end
          CACHE_READ_DONE: begin
            cache_read_ready <= 1'b1;
          end
          default: begin
            cache_update_ea_p <= 1'b0;
            cache_write_ea_p  <= 1'b0;
            cache_read_ea_p   <= 1'b0;
            cache_read_ready  <= 1'b1;
          end
        endcase
      end
    end
  end

  always_ff @(posedge clk) begin : FW_NC_OUT_BEAT
    if (rst_p || fw_reset) begin
      nc_out_beat <= 0;
    end else begin
      if (cache_state == CACHE_SLEEP) begin
        if (nc_in_ready) begin
          nc_out_beat.data    <= fwt_out_beat.data;
          nc_out_beat.index   <= fwt_out_beat.index;
          nc_out_beat.valid   <= 0;
          nc_out_beat.stop    <= fwt_out_beat.stop;
          nc_out_beat.waiting <= fwt_out_beat.waiting;
          nc_out_beat.error   <= fwt_out_beat.error;
        end else if (nc_out_ready) begin
          nc_out_beat.valid <= 0;
        end
      end else if (cache_state == CACHE_READ_DONE) begin
        nc_out_beat.valid <= 1;
        if (cache_exists) begin
          nc_out_beat.data.data.dst  <= cache_mac_addr_o;
          nc_out_beat.data.meta.dest <= cache_iface_o;
        end else begin
          if (nc_out_beat.error == ERR_NONE) begin
            // Neighbor Cache Miss Has Lower Priority
            nc_out_beat.error <= ERR_NC_MISS;
          end
        end
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
        if (fwo_state == FWO_SEND_1) begin
          // Send first pack
          out.valid                <= 1'b1;
          // Construct IPv6 header
          out.data.ip6.p           <= fw_out_first_beat.data.data.ip6.p;
          out.data.ip6.dst         <= fw_out_first_beat.data.data.ip6.dst;
          out.data.ip6.src         <= fw_out_first_beat.data.data.ip6.src;
          out.data.ip6.hop_limit   <= fw_out_first_beat.data.data.ip6.hop_limit - 1;
          out.data.ip6.next_hdr    <= fw_out_first_beat.data.data.ip6.next_hdr;
          out.data.ip6.payload_len <= fw_out_first_beat.data.data.ip6.payload_len;
          out.data.ip6.flow_lo     <= fw_out_first_beat.data.data.ip6.flow_lo;
          out.data.ip6.version     <= fw_out_first_beat.data.data.ip6.version;
          out.data.ip6.flow_hi     <= fw_out_first_beat.data.data.ip6.flow_hi;
          // Construct Ether header
          out.data.ethertype       <= fw_out_first_beat.data.data.ethertype;
          out.data.dst             <= fw_out_first_beat.data.data.dst;
          case (fw_out_port)
            2'd0: out.data.src <= mac_addrs[0];
            2'd1: out.data.src <= mac_addrs[1];
            2'd2: out.data.src <= mac_addrs[2];
            2'd3: out.data.src <= mac_addrs[3];
            default: out.data.src <= 48'h0;
          endcase
          // Meta data
          out.is_first        <= fw_out_first_beat.data.is_first;
          out.last            <= fw_out_first_beat.data.last;
          out.keep            <= fw_out_first_beat.data.keep;
          out.meta.dest       <= fw_out_port;
          out.meta.dont_touch <= fw_out_first_beat.data.meta.dont_touch;
          out.meta.drop_next  <= fw_out_first_beat.data.meta.drop_next;
          out.meta.drop       <= fw_out_first_beat.data.meta.drop;
        end else if (fwo_state == FWO_SEND_F) begin
          // Send the rest of the packs
          out.valid           <= 1'b1;
          // Inherit the data from the input
          out.data            <= fw_out_following_beat.data.data;
          // Mata data
          out.is_first        <= fw_out_following_beat.data.is_first;
          out.last            <= fw_out_following_beat.data.last;
          out.keep            <= fw_out_following_beat.data.keep;
          out.meta.dest       <= fw_out_port;
          out.meta.dont_touch <= fw_out_following_beat.data.meta.dont_touch;
          out.meta.drop_next  <= fw_out_following_beat.data.meta.drop_next;
          out.meta.drop       <= fw_out_following_beat.data.meta.drop;
        end else if (fwo_state == FWO_DONE) begin
          // do nothing
          out.valid <= 1'b0;
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
        end else if (
                      (state == DP_FWD)    &&
                      (fwt_out_beat.valid) &&
                      (!fwt_out_beat.stop) &&
                      (nc_in_ready)
                    ) begin
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
        ns_next_state = ((state_reg == DP_IDLE || state_reg == DP_FWD) &&
                                             (next_state_reg == DP_NS))  ? NS_WAIT : NS_IDLE;
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
        na_next_state = ((state_reg == DP_IDLE || state_reg == DP_FWD) &&
                                             (next_state_reg == DP_NA)) ? NA_WAIT : NA_IDLE;
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
        if(fw_out_should_stop) begin
          next_state = fw_out_state;
        end else begin
          next_state = DP_FWD;
        end
      end
      default: begin
        next_state = DP_IDLE;
      end
    endcase
  end

endmodule : datapath_sm
