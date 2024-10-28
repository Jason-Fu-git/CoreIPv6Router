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
  // ===  NAMING ===
  // fwi_ : Forward Logic Pipline Input Selector
  // fwo_ : Forward Logic Pipline Output Selector
  // fw_  : Forward Logic Pipline
  // fwt_ : Forward Table
  // nc_  : Neighbor Cache
  // =============================================================

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

  logic fwi_beat_1_in_ready;
  logic fwi_beat_f_in_ready;
  logic fwo_in_ready;


  // ================
  // Judge input type
  // ================
  typedef enum logic [2:0] {
    FW_TYPE_NS,
    FW_TYPE_NA,
    FW_TYPE_IPV6,
    FW_TYPE_OTHERS
  } fwi_type_t;
  fwi_type_t fwi_type;

  always_comb begin : FW_InputType
    fwi_type = FW_TYPE_OTHERS;
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
          fwi_type = FW_TYPE_NS;
        end else if(
                 (in.data.ip6.next_hdr == IP6_HDR_TYPE_ICMPv6)
              && (in.data.ip6.p[7:0] == ICMPv6_HDR_TYPE_NA)
              && (in.data.ip6.hop_limit == IP6_HDR_HOP_LIMIT_DEFAULT)
              && (in.data.ip6.p[15:8] == 0)
              && ({in.data.ip6.payload_len[7:0], in.data.ip6.payload_len[15:8]} >= 16'd24)
              && (in.data.ip6.payload_len[10:8] == 3'b000)
              && (in.data.ip6.src != 0)
          ) begin
          fwi_type = FW_TYPE_NA;
        end else if (in.data.ip6.hop_limit > 1) begin
          fwi_type = FW_TYPE_IPV6;
        end else begin  // Invalid Hop Limit. Drop it.
          fwi_type = FW_TYPE_OTHERS;
        end
      end
    end
  end


  // =================
  // Input selector
  // =================
  fw_frame_beat_t       fwi_beat_1;
  fw_frame_beat_t       fwi_beat_f;
  reg             [4:0] fwi_counter;  // 0 is reserved
  reg                   fwi_should_stop;
  dp_state_t            fw_out_state;
  assign fw_in_ready =  !fwi_should_stop &&
                        (
                          (fwi_beat_1_in_ready && in.is_first) ||
                          (fwi_beat_f_in_ready && !in.is_first)
                        );

  // valid = 0 means bubble. Its index should be the previous valid beat's index.
  always_ff @(posedge clk) begin : FW_InputSelector
    if (rst_p || fw_reset) begin
      fwi_beat_1      <= 0;
      fwi_beat_f      <= 0;
      fwi_counter     <= 0;
      fwi_should_stop <= 1;
      fw_out_state    <= DP_IDLE;
    end else begin
      if (state == DP_IDLE && next_state == DP_FWD) begin
        // Reset Stop Signal
        fwi_should_stop <= 0;
      end else begin
        // First Beat
        if (fwi_beat_1_in_ready) begin
          if (fwi_should_stop) begin
            // Insert stop signal.
            fwi_beat_1.valid   <= 1; // Not a bubble.
            fwi_beat_1.stop    <= 1;
            fwi_beat_1.waiting <= 0;
            fwi_beat_1.error   <= ERR_NONE;
          end else begin
            if (`should_handle(in)) begin
              // Set Data
              fwi_beat_1.data <= in;
              // Set Index
              if (fwi_counter == 5'b11111) begin
                fwi_counter      <= 1;
                fwi_beat_1.index <= 1;
              end else begin
                fwi_counter      <= fwi_counter + 1;
                fwi_beat_1.index <= fwi_counter + 1;
              end
              // Set Valid
              fwi_beat_1.valid <= 1;
              // Set Other Signals
              case (fwi_type)
                FW_TYPE_IPV6: begin
                  // Process the first beat
                  fwi_should_stop    <= 0;
                  fwi_beat_1.waiting <= 1;
                  fwi_beat_1.stop    <= 0;
                  fwi_beat_1.error   <= ERR_NONE;
                  fw_out_state       <= DP_IDLE;
                end
                FW_TYPE_NS: begin
                  // Stop Forward Logic
                  fwi_should_stop    <= 1;
                  fwi_beat_1.waiting <= 0;
                  fwi_beat_1.stop    <= 1;
                  fwi_beat_1.error   <= ERR_WRONG_TYPE;
                  fw_out_state       <= DP_NS;
                end
                FW_TYPE_NA: begin
                  // Stop Forward Logic
                  fwi_should_stop    <= 1;
                  fwi_beat_1.waiting <= 0;
                  fwi_beat_1.stop    <= 1;
                  fwi_beat_1.error   <= ERR_WRONG_TYPE;
                  fw_out_state       <= DP_NA;
                end
                default: begin
                  fwi_beat_1.waiting <= 1;
                  fwi_beat_1.stop    <= 0;
                  fwi_beat_1.error   <= ERR_WRONG_TYPE;
                  fw_out_state       <= DP_IDLE;
                end
              endcase
            end else begin  // Should not handle
              fwi_beat_1.valid   <= 0; // insert a bubble
              fwi_beat_1.waiting <= 0;
              fwi_beat_1.stop    <= 0;
              fwi_beat_1.error   <= ERR_NONE;
            end
          end
        end
        // Following Beat
        if (fwi_beat_f_in_ready) begin
          fwi_beat_f.index <= fwi_counter;
          if (fwi_should_stop) begin
            // Insert a stop signal. Note : It's not a bubble!
            fwi_beat_f.valid   <= 1; // Not a bubble.
            fwi_beat_f.waiting <= 0;
            fwi_beat_f.stop    <= 1;
            fwi_beat_f.error   <= ERR_NONE;
          end else begin
            if (`should_handle_following(in)) begin
              // Pass the following beats
              fwi_beat_f.data    <= in;
              fwi_beat_f.valid   <= 1;
              fwi_beat_f.waiting <= 1;
              fwi_beat_f.stop    <= 0;
              fwi_beat_f.error   <= ERR_NONE;
            end else begin
              // Invalid input
              fwi_beat_f.valid   <= 0; // Insert a bubble.
              fwi_beat_f.waiting <= 0;
              fwi_beat_f.stop    <= 0;
              fwi_beat_f.error   <= ERR_NONE;
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
  assign fwi_beat_1_in_ready = fwt_in_ready || !fwi_beat_1.valid;
  assign fwt_in_beat         = fwi_beat_1;

  // Neighbor Cache
  logic nc_in_ready;
  assign fwt_out_ready = nc_in_ready;

  logic           nc_out_ready;
  fw_frame_beat_t nc_out_beat;
  assign nc_in_ready = (nc_out_ready || !nc_out_beat.valid) && cache_read_ready;


  logic fwo_beat_1_in_ready;
  assign nc_out_ready = fwo_beat_1_in_ready;

  // =================
  // Process Following Beat
  // =================

  // TODO: Customize the delay
  // Toy Example: 3 beats delay
  // Beat 1 (= fwi_beat_f)
  fw_frame_beat_t fw_beat_f_1;
  logic           fw_beat_f_1_in_ready;
  assign fw_beat_f_1         = fwi_beat_f;
  assign fwi_beat_f_in_ready = fw_beat_f_1_in_ready;

  // Beat 2
  fw_frame_beat_t fw_beat_f_2;
  logic           fw_beat_f_2_in_ready;
  assign fw_beat_f_1_in_ready = fw_beat_f_2_in_ready || !fw_beat_f_1.valid;
  always_ff @(posedge clk) begin : FW_FollowingBeat_2
    if (rst_p || fw_reset) begin
      fw_beat_f_2 <= 0;
    end else begin
      if (fw_beat_f_2_in_ready) begin
        fw_beat_f_2 <= fw_beat_f_1;
      end
    end
  end

  // Beat 3
  fw_frame_beat_t fw_beat_f_3;
  logic           fw_beat_f_3_in_ready;
  assign fw_beat_f_2_in_ready = fw_beat_f_3_in_ready || !fw_beat_f_2.valid;
  always_ff @(posedge clk) begin : FW_FollowingBeat_3
    if (rst_p || fw_reset) begin
      fw_beat_f_3 <= 0;
    end else begin
      if (fw_beat_f_3_in_ready) begin
        fw_beat_f_3 <= fw_beat_f_2;
      end
    end
  end

  logic fwo_beat_f_in_ready;
  assign fw_beat_f_3_in_ready = fwo_beat_f_in_ready;

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
  fw_frame_beat_t fwo_beat_1;
  fw_frame_beat_t fwo_beat_f;
  assign fwo_in_ready = fwo_beat_1_in_ready || fwo_beat_f_in_ready;

  // Counter : 31 Max
  localparam UPPER_LIMIT = 5'd25;
  localparam LOWER_LIMIT = 5'd6;
  logic fwo_beat_1_should_send;  // Whether the first beat should be sent
  assign fwo_beat_1_should_send = (!fwo_beat_f.valid) ||
                                     (fwo_beat_f.valid &&
                                      (
                                          (
                                            (fwo_beat_1.index < LOWER_LIMIT) &&
                                            (fwo_beat_f.index < UPPER_LIMIT) &&
                                            (fwo_beat_1.index < fwo_beat_f.index)
                                          ) ||
                                          (
                                            (fwo_beat_1.index >= LOWER_LIMIT) &&
                                            (fwo_beat_1.index < UPPER_LIMIT) &&
                                            (fwo_beat_1.index < fwo_beat_f.index)
                                          ) ||
                                          (
                                            (fwo_beat_1.index >= UPPER_LIMIT) &&
                                            (fwo_beat_f.index >= LOWER_LIMIT) &&
                                            (fwo_beat_1.index < fwo_beat_f.index)
                                          ) ||
                                          (
                                            (fwo_beat_1.index >= UPPER_LIMIT) &&
                                            (fwo_beat_f.index < LOWER_LIMIT)
                                          ) ||
                                          (
                                            (fwo_beat_1.index == fwo_beat_f.index) &&
                                            (fwo_beat_1.waiting)
      // Not Waiting Implies the first beat has been sent
      )));

  // Interface
  logic [1:0] fw_out_port;

  // Out Ready Signal
  assign fwo_beat_1_in_ready = (fwo_state == FWO_IDLE) &&
                                      (
                                        (!fwo_beat_1.valid) ||
                                        (fwo_beat_1.valid && !fwo_beat_1.waiting)
                                      );
  assign fwo_beat_f_in_ready = (fwo_state == FWO_IDLE) &&
                                      (
                                        (!fwo_beat_f.valid) ||
                                        (fwo_beat_f.valid && !fwo_beat_f.waiting)
                                      );

  // Should send signal
  logic fwo_should_send;
  assign fwo_should_send     = out_ready && (
                                              (
                                                fwo_beat_1.waiting &&
                                                fwo_beat_1.valid &&
                                                fwo_beat_1_should_send
                                              ) ||
                                              (
                                                fwo_beat_f.waiting &&
                                                fwo_beat_f.valid &&
                                                !fwo_beat_1_should_send
                                              )
                                            );
  logic fwo_should_stop;
  assign fwo_should_stop = fwo_beat_1.stop && fwo_beat_f.stop;

  // Output Selector
  always_ff @(posedge clk) begin : FW_OutputSelector
    if (rst_p || fw_reset) begin
      // state machine
      fwo_state   <= FWO_IDLE;
      // Interface
      fw_out_port <= 0;
      // Out beat
      fwo_beat_1  <= 0;
      fwo_beat_f  <= 0;
    end else begin
      case (fwo_state)
        FWO_IDLE: begin
          // Save the first beat
          if (fwo_beat_1_in_ready) begin
            // FW Signals
            fwo_beat_1.valid <= nc_out_beat.valid;
            fwo_beat_1.stop  <= nc_out_beat.stop;
            fwo_beat_1.index <= nc_out_beat.index;
            fwo_beat_1.error <= nc_out_beat.error;
            if (fwo_beat_1.index != nc_out_beat.index) begin
              fwo_beat_1.waiting <= nc_out_beat.waiting;
            end
            // FW Data
            fwo_beat_1.data.data            <= nc_out_beat.data.data;
            fwo_beat_1.data.keep            <= nc_out_beat.data.keep;
            fwo_beat_1.data.last            <= nc_out_beat.data.last;
            fwo_beat_1.data.user            <= nc_out_beat.data.user;
            fwo_beat_1.data.valid           <= nc_out_beat.data.valid;
            fwo_beat_1.data.is_first        <= nc_out_beat.data.is_first;
            // Meta
            fwo_beat_1.data.meta.id         <= nc_out_beat.data.meta.id;
            fwo_beat_1.data.meta.dest       <= nc_out_beat.data.meta.dest;
            fwo_beat_1.data.meta.dont_touch <= nc_out_beat.data.meta.dont_touch;
            fwo_beat_1.data.meta.drop_next  <= nc_out_beat.data.meta.drop_next;
            // Check its error. And set drop signal
            case (nc_out_beat.error)
              ERR_NONE: begin
                fwo_beat_1.data.meta.drop <= 0;
              end
              ERR_FWT_MISS: begin
                fwo_beat_1.data.meta.drop <= 1;
              end
              ERR_NC_MISS: begin
                fwo_beat_1.data.meta.drop <= 1;
              end
              ERR_WRONG_TYPE: begin
                fwo_beat_1.data.meta.drop <= 1;
              end
              default: begin
                fwo_beat_1.data.meta.drop <= 1;
              end
            endcase
          end
          // Save the following beat
          if (fwo_beat_f_in_ready) begin
            fwo_beat_f <= fw_beat_f_3;
          end
          // If there is a packet to send, transfer to FWO_SELECT
          if (fwo_should_send && !fwo_should_stop) begin
            fwo_state <= FWO_SELECT;
          end
        end
        FWO_SELECT: begin
          if (fwo_beat_1_should_send) begin
            if (fwo_beat_1.valid && !fwo_beat_1.stop) begin
              // Not an empty beat. Not a stop beat
              fwo_state   <= FWO_SEND_1;
              fw_out_port <= fwo_beat_1.data.meta.dest;
            end else begin
              // Empty first beat or stop first beat
              fwo_beat_1.waiting <= 0;
              fwo_state          <= FWO_IDLE;
            end
          end else begin
            if (fwo_beat_f.valid && !fwo_beat_f.stop) begin
              fwo_state <= FWO_SEND_F;
            end else begin
              // Empty following beat, drop it
              fwo_state          <= FWO_IDLE;
              fwo_beat_f.waiting <= 0;
            end
          end
        end
        FWO_SEND_1: begin
          fwo_beat_1.waiting <= 0;
          fwo_state          <= FWO_DONE;
        end
        FWO_SEND_F: begin
          fwo_beat_f.waiting <= 0;
          fwo_state          <= FWO_DONE;
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
          nc_out_beat.valid   <= 0; // Insert a bubble
          nc_out_beat.stop    <= fwt_out_beat.stop;
          nc_out_beat.waiting <= fwt_out_beat.waiting;
          nc_out_beat.error   <= fwt_out_beat.error;
        end else if (nc_out_ready) begin
          nc_out_beat.valid <= 0; // Insert a bubble
        end
      end else if (cache_state == CACHE_READ_DONE) begin
        nc_out_beat.valid <= 1; // Cache Read Done. Send it.
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
          out.data.ip6.p           <= fwo_beat_1.data.data.ip6.p;
          out.data.ip6.dst         <= fwo_beat_1.data.data.ip6.dst;
          out.data.ip6.src         <= fwo_beat_1.data.data.ip6.src;
          out.data.ip6.hop_limit   <= fwo_beat_1.data.data.ip6.hop_limit - 1;
          out.data.ip6.next_hdr    <= fwo_beat_1.data.data.ip6.next_hdr;
          out.data.ip6.payload_len <= fwo_beat_1.data.data.ip6.payload_len;
          out.data.ip6.flow_lo     <= fwo_beat_1.data.data.ip6.flow_lo;
          out.data.ip6.version     <= fwo_beat_1.data.data.ip6.version;
          out.data.ip6.flow_hi     <= fwo_beat_1.data.data.ip6.flow_hi;
          // Construct Ether header
          out.data.ethertype       <= fwo_beat_1.data.data.ethertype;
          out.data.dst             <= fwo_beat_1.data.data.dst;
          case (fw_out_port)
            2'd0: out.data.src <= mac_addrs[0];
            2'd1: out.data.src <= mac_addrs[1];
            2'd2: out.data.src <= mac_addrs[2];
            2'd3: out.data.src <= mac_addrs[3];
            default: out.data.src <= 48'h0;
          endcase
          // Meta data
          out.is_first        <= fwo_beat_1.data.is_first;
          out.last            <= fwo_beat_1.data.last;
          out.keep            <= fwo_beat_1.data.keep;
          out.meta.dest       <= fw_out_port;
          out.meta.dont_touch <= fwo_beat_1.data.meta.dont_touch;
          out.meta.drop_next  <= fwo_beat_1.data.meta.drop_next;
          out.meta.drop       <= fwo_beat_1.data.meta.drop;
        end else if (fwo_state == FWO_SEND_F) begin
          // Send the rest of the packs
          out.valid           <= 1'b1;
          // Inherit the data from the input
          out.data            <= fwo_beat_f.data.data;
          // Mata data
          out.is_first        <= fwo_beat_f.data.is_first;
          out.last            <= fwo_beat_f.data.last;
          out.keep            <= fwo_beat_f.data.keep;
          out.meta.dest       <= fw_out_port;
          out.meta.dont_touch <= fwo_beat_f.data.meta.dont_touch;
          out.meta.drop_next  <= fwo_beat_f.data.meta.drop_next;
          out.meta.drop       <= fwo_beat_f.data.meta.drop;
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
                      (fwt_out_beat.valid) && // Bubble should not be processed
                      (!fwt_out_beat.stop) && // Stop signal should not be processed
                      (nc_in_ready) // New signal arrived
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
        if (fwo_should_stop) begin
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
