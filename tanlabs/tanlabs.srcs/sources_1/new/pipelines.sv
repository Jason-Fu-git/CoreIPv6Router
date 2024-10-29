`timescale 1ns / 1ps

`include "frame_datapath.vh"

// valid_i is in_valid
// ready_i is out_ready
// valid_o is out_valid
// ready_o is in_ready

module pipeline_ns (
	input  wire         clk,
	input  wire         rst_p,
	
	input  wire         valid_i,  // Last pipeline valid
	input  wire         ready_i,  // Next pipeline ready
	output reg          valid_o,  // To the next pipeline
	output reg          ready_o,  // To the last pipeline

	input  frame_beat   in,
	output frame_beat   out,

	input  wire [3:0] [ 47:0] mac_addrs,   // router MAC address
    input  wire [3:0] [127:0] ipv6_addrs   // router IPv6 address
);

	frame_beat first_beat;

	logic [1:0] in_meta_src;

	assign in_meta_src = first_beat.meta.id;

	typedef enum logic [3:0] {
		NS_IDLE,
		NS_WAIT,
		NS_CHECK_NS,
		NS_SEND_1,
		NS_CHECK_NA,
		NS_SEND_2
	} ns_state_t;
	
	ns_state_t ns_state, ns_next_state;

	NS_packet ns_packet;  // NS packet stored from input
	NA_packet na_packet;  // Here checksum is set to 0; do not send this directly

	logic [15:0] ns_checksum;
	logic [15:0] na_checksum;
	logic [15:0] na_checksum_reg;

	logic ns_checksum_valid;
	logic na_checksum_valid;
	logic ns_checksum_ea;
	logic na_checksum_ea;
	logic ns_checksum_ok;

	logic ns_legal;

	assign ns_legal = (
		(ns_packet.option.len > 0)
	 && (ns_packet.icmpv6.target_addr[7:0] != 8'hff)
	 && (ns_checksum_ok)
	 && (ipv6_addrs[in_meta_src] == ns_packet.icmpv6.target_addr));

	always_comb begin
		case (ns_state)
			NS_IDLE     : ns_next_state = ((valid_i          ) ? NS_WAIT     : NS_IDLE    );
			NS_WAIT     : ns_next_state = ((valid_i          ) ? NS_CHECK_NS : NS_WAIT    );
			NS_CHECK_NS : ns_next_state = ((ns_checksum_valid) ? NS_SEND_1   : NS_CHECK_NS);
			NS_SEND_1   : ns_next_state = ((ready_i          ) ? NS_CHECK_NA : NS_SEND_1  );
			NS_CHECK_NA : ns_next_state = ((na_checksum_valid) ? NS_SEND_2   : NS_CHECK_NA);
			NS_SEND_2   : ns_next_state = ((ready_i          ) ? NS_IDLE     : NS_SEND_2  );
			default     : ns_next_state = NS_IDLE;
		endcase
	end

	always_ff @(posedge clk) begin
		if (rst_p) begin
			ns_state <= NS_IDLE;
		end else begin
			ns_state <= ns_next_state;
		end
	end

	always_ff @(posedge clk) begin
		if (rst_p) begin
			first_beat <= 0;
			out <= 0;
			ns_packet <= 0;
			ns_checksum_ea <= 0;
			ns_checksum_ok <= 0;
			na_checksum_reg <= 0;
			na_checksum_ea <= 0;
		end else begin
			if (ns_checksum_valid) begin
				ns_checksum_ok <= (ns_checksum == 16'hffff);
			end
			if          ((ns_state == NS_IDLE) && (valid_i)) begin
				first_beat <= in;
			end else if ((ns_state == NS_WAIT) && (valid_i)) begin
				ns_packet <= {in.data, first_beat.data};
				ns_checksum_ea <= 1'b1;
				na_checksum_ea <= 1'b1;
			end else if ((ns_state == NS_SEND_1) && (ready_i)) begin
				ns_checksum <= 0;
				ns_checksum_ok <= 0;
			end else if ((ns_state == NS_SEND_2) && (ready_i)) begin
				na_checksum_ea <= 0;
			end
			if (ns_state == NS_WAIT) begin
				out.data            <= na_packet[447:0];  // 56 bytes
				out.is_first        <= 1'b1;
				out.last            <= 1'b0;  // Not the last pack
				out.valid           <= 1'b0;  // Wait for ND_SEND_1 to send
				out.keep            <= 56'hffffffffffffff;  // Full pack
				out.meta.dont_touch <= 1'b0;
				out.meta.drop_next  <= 1'b0;
				out.meta.dest       <= in_meta_src;
			end else if (ns_state == NS_SEND_1) begin
				out.valid <= 1;
				out.meta.drop <= !ns_legal;
			end else if (ns_state == NS_SEND_2) begin
				out.data <= {208'h0, na_packet[687:448]};  // 86 - 56 = 30 bytes
				out.data[15:0] <= ~{na_checksum[7:0], na_checksum[15:8]};
				out.is_first <= 1'b0;
				out.last <= 1'b1;  // The last pack
				out.valid <= 1'b1;  // Send directly
				out.keep            <= 56'h0000003fffffff;                // 30 bytes valid: 0b...11_1111_1111_1111_1111_1111_1111_1111
				out.meta.drop <= 1'b0;
				out.meta.dont_touch <= 1'b0;
				out.meta.drop_next <= 1'b0;
				out.meta.dest <= in_meta_src;
			end else begin
				out.valid <= 0;
			end
		end
	end

	always_comb begin
		na_packet.option.option_type    = 8'd2;
		na_packet.option.len            = 8'd1;
		na_packet.icmpv6.icmpv6_type    = ICMPv6_HDR_TYPE_NA;  // 8'd136
		na_packet.icmpv6.code           = 8'd0;
		na_packet.icmpv6.checksum       = 16'd0;
		na_packet.icmpv6.R              = 1'b1;  // sent from router
		na_packet.icmpv6.S              = 1'b1;  // TODO: set the flag, now is default: sent as response to NS
		na_packet.icmpv6.O              = 1'b0;  // TODO: set the flag
		na_packet.icmpv6.reserved_lo    = 24'h0;
		na_packet.icmpv6.reserved_hi    = 5'h0;
		na_packet.icmpv6.target_addr    = in_ip6_hdr.src;
		na_packet.ether.dst             = in_ether_hdr.src;
		na_packet.ether.ethertype       = 16'hdd86;  // IPv6
		na_packet.ether.ip6.dst         = in_ip6_hdr.src;
		na_packet.ether.ip6.next_hdr    = IP6_HDR_TYPE_ICMPv6;  // 8'd58
		na_packet.ether.ip6.hop_limit   = IP6_HDR_HOP_LIMIT_DEFAULT;  // 8'd255
		na_packet.ether.ip6.payload_len = {
			32, 8'd0
		};  // 24 bytes for ICMPv6 header, 8 bytes for option
		na_packet.ether.ip6.flow_lo     = 24'b0;
		na_packet.ether.ip6.flow_hi     = 4'b0;
		na_packet.ether.ip6.version     = 4'd6;
		na_packet.option.mac_addr       = mac_addrs[in_meta_src];
		na_packet.ether.src             = mac_addrs[in_meta_src];
		na_packet.ether.ip6.src         = ipv6_addrs[in_meta_src];
	end

	assign valid_o        = ((ns_state == NS_SEND_1) || (ns_state == NS_SEND_2));
	assign ready_o        = ((ns_state == NS_IDLE  ) || (ns_state == NS_WAIT  ));

	checksum_calculator checksum_calculator_ns (
		.clk            (clk),
		.rst_p          (rst_p),
		.ip6_src        (ns_packet.ether.ip6.src),
		.ip6_dst        (ns_packet.ether.ip6.dst),
		.payload_length ({16'd0, ns_packet.ether.ip6.payload_len}),
		.next_header    (ns_packet.ether.ip6.next_hdr),
		.current_payload({ns_packet.option, ns_packet.icmpv6}),
		.mask           (~(256'd0)),
		.is_first       (1'b1),
		.ea_p           (ns_checksum_ea),
		.checksum       (ns_checksum),
		.valid          (ns_checksum_valid)
	);

	checksum_calculator checksum_calculator_ns_na (
		.clk            (clk),
		.rst_p          (rst_p),
		.ip6_src        (na_packet.ether.ip6.src),
		.ip6_dst        (na_packet.ether.ip6.dst),
		.payload_length ({16'd0, na_packet.ether.ip6.payload_len}),
		.next_header    (na_packet.ether.ip6.next_hdr),
		.current_payload({na_packet.option, na_packet.icmpv6}),
		.mask           (~(256'd0)),
		.is_first       (1'b1),
		.ea_p           (na_checksum_ea),
		.checksum       (na_checksum),
		.valid          (na_checksum_valid)
	);

endmodule : pipeline_ns

module pipeline_na (
	input  wire         clk,
	input  wire         rst_p,
	
	input  wire         valid_i,  // Last pipeline valid
	input  wire         ready_i,  // Cache ready
	output reg          ready_o,  // To the last pipeline
	output reg          valid_o,  // Write cache valid

	input  frame_beat   in,
	output cache_entry  out,

	input  wire [3:0] [ 47:0] mac_addrs,   // router MAC address
    input  wire [3:0] [127:0] ipv6_addrs   // router IPv6 address
);

	frame_beat first_beat;

	logic [1:0] in_meta_src;

	assign in_meta_src = first_beat.meta.id;

	NA_packet na_packet;
	logic [15:0] na_checksum;
	logic na_checksum_ea;
	logic na_checksum_ok;
	logic na_checksum_valid;
	logic na_valid;

	assign na_valid = ((na_packet.option.len > 0) && (na_checksum_ok));

	typedef enum logic [3:0] {
		NA_IDLE ,    // Wait for an NA pack
		NA_WAIT ,    // Wait for the second pack to arrive
		NA_CHECK,    // Wait for NA checksum
		NA_CACHE     // Write ND cache
	} na_state_t;

	na_state_t na_state, na_next_state;

	always_ff @(posedge clk) begin
		if (rst_p) begin
			na_state <= NA_IDLE;
		end else begin
			na_state <= na_next_state;
		end
	end

	always_ff @(posedge clk) begin
		if (rst_p) begin
			out <= 0;
			first_beat <= 0;
			na_packet <= 0;
			na_checksum_ea <= 0;
			na_checksum_ok <= 0;
		end else begin
			if (na_checksum_valid) begin
				na_checksum_ok <= (na_checksum == 16'hffff);
			end
			if ((na_state == NA_IDLE) && valid_i) begin
				first_beat <= in;
			end else if ((na_state == NA_WAIT) && valid_i) begin
				na_packet      <= {in.data, first_beat.data};
				na_checksum_ea <= 1'b1;
			end else if ((na_state == NA_CHECK) && na_checksum_valid) begin
				na_checksum_ea <= 1'b0;
				na_checksum_ok <= 1'b0;
				out.ip6_addr <= na_packet.ether.ip6.src;
				out.mac_addr <= na_packet.option.mac_addr;
				out.iface    <= in_meta_src;
			end
		end
	end

	always_comb begin
		case (na_state)
			NA_IDLE: begin
				na_next_state = (valid_i) ? NA_WAIT : NA_IDLE;
			end
			NA_WAIT: begin
				na_next_state = (valid_i) ? NA_CHECK : NA_WAIT;
			end
			NA_CHECK: begin
				na_next_state = (na_checksum_valid) ? ((na_checksum == 16'hffff) ? NA_CACHE : NA_IDLE) : NA_CHECK;
			end
			NA_CACHE: begin
				na_next_state = (ready_i) ? NA_IDLE : NA_CACHE;
			end
			default: begin
				na_next_state = NA_IDLE;
			end
		endcase
	end

	assign valid_o = (na_state == NA_CACHE);
	assign ready_o = ((na_state == NA_IDLE) || (ns_state == NA_WAIT));


	checksum_calculator checksum_calculator_na (
		.clk            (clk),
		.rst_p          (rst_p),
		.ip6_src        (na_packet.ether.ip6.src),
		.ip6_dst        (na_packet.ether.ip6.dst),
		.payload_length ({16'd0, na_packet.ether.ip6.payload_len}),
		.next_header    (na_packet.ether.ip6.next_hdr),
		.current_payload({na_packet.option, na_packet.icmpv6}),
		.mask           (~(256'd0)),
		.is_first       (1'b1),
		.ea_p           (na_checksum_ea),
		.checksum       (na_checksum),
		.valid          (na_checksum_valid)
	);

endmodule : pipeline_na

module pipeline_nud(
    input  wire          clk       ,
    input  wire          rst_p     ,
    input  wire          we_i      , // needed to send NS, trigger
    input  logic [127:0] tgt_addr_i, // target address
    input  logic [127:0] ip6_addr_i, // self IPv6 address
    input  logic [ 47:0] mac_addr_i, // self MAC address
    input  logic [  1:0] iface_i   , // interface ID (0, 1, 2, 3)
    input  logic         ready_i   , // out can be sent
	output frame_beat    out       ,
	output logic         valid_o
);

    NS_packet     NS_o;  // NS packet to be sent by datapath
    logic [ 15:0] checksum_o;  // checksum of NS packet
	logic         checksum_ea;
    logic         checksum_valid;

	typedef enum logic [3:0] {
		NUD_IDLE,
		NUD_CHECK,
		NUD_SEND_1,
		NUD_SEND_2
	} nud_state_t;

	nud_state_t nud_state, nud_next_state;

	always_ff @(posedge clk) begin
		if (rst_p) begin
			nud_state <= NUD_IDLE;
		end else begin
			nud_state <= nud_next_state;
		end
	end

    logic [127:0] sn_addr; // solicited-node address
    logic [127:0] tgt_addr;
    logic [127:0] ip6_addr;
    logic [ 47:0] mac_addr;
    logic [  1:0] iface;

    always_comb begin
        sn_addr[103:0] = {104'h010000000000000000000002ff};
    end

    always_ff @(posedge clk) begin
        if (rst_p) begin
			out <= 0;
            sn_addr[127:104] <= 24'b0;
            tgt_addr <= 128'b0;
            ip6_addr <= 128'b0;
            mac_addr <= 48'b0;
            iface <= 2'b0;
			checksum_ea <= 1'b0;
        end else begin
            if ((nud_state == NUD_IDLE) && we_i) begin
                sn_addr[127:104] <= tgt_addr_i[127:104];
                tgt_addr <= tgt_addr_i;
                ip6_addr <= ip6_addr_i;
                mac_addr <= mac_addr_i;
                iface <= iface_i;
				checksum_ea <= 1'b1;
			end else if ((nud_state == NUD_SEND_2) && ready_i) begin
				checksum_ea <= 1'b0;
			end
			if (nud_state == NUD_SEND_1) begin
				out.data <= NS_o[447:0];
				out.is_first <= 1'b1;
				out.is_last <= 1'b0;
				out.valid <= 1'b1;
				out.keep <= 56'hffffffffffffff;
				out.meta.drop <= 1'b0;
				out.meta.dont_touch <= 1'b0;
				out.meta.drop_next <= 1'b0;
				out.meta.dest <= iface;
			end else if (nud_state == NUD_SEND_2) begin
				out.data <= {208'h0, NS_o[687:448]};
				out.data[15:0] <= ~{checksum_o[7:0], checksum_o[15:8]};
				out.is_first        <= 1'b0;
				out.last            <= 1'b1;
				out.valid           <= 1'b1;
				out.keep            <= 56'h0000003fffffff;
				out.meta.drop       <= 1'b0;
				out.meta.dont_touch <= 1'b0;
				out.meta.drop_next  <= 1'b0;
				out.meta.dest       <= iface;
			end else begin
				out.valid <= 1'b0;
			end
        end
    end

    always_comb begin
        NS_o.ether.ip6.dst = sn_addr;
        NS_o.ether.ip6.src = ip6_addr;
        NS_o.ether.ip6.hop_limit = 255;
        NS_o.ether.ip6.next_hdr = IP6_HDR_TYPE_ICMPv6;
        NS_o.ether.ip6.payload_len = {8'd32, 8'd0};
        NS_o.ether.ip6.flow_lo = 24'b0;
        NS_o.ether.ip6.flow_hi = 4'b0;
        NS_o.ether.ip6.version = 4'd6;
        NS_o.ether.ethertype = 16'hdd86; // IPv6
        NS_o.ether.src = mac_addr;
        NS_o.ether.dst = {sn_addr[127:96], 16'h3333};
        NS_o.option.mac_addr = mac_addr;
        NS_o.option.len = 8'd1;
        NS_o.option.option_type = 8'd1;
        NS_o.icmpv6.target_addr = tgt_addr;
        NS_o.icmpv6.reserved_lo = 24'b0;
        NS_o.icmpv6.R = 1'b0;
        NS_o.icmpv6.S = 1'b0;
        NS_o.icmpv6.O = 1'b0;
        NS_o.icmpv6.reserved_hi = 5'b0;
        NS_o.icmpv6.code = 8'd0;
        NS_o.icmpv6.icmpv6_type = ICMPv6_HDR_TYPE_NS;
        NS_o.icmpv6.checksum = 16'b0;
    end

	always_comb begin
		case (nud_state)
			NUD_IDLE: nud_next_state = we_i ? NUD_CHECK : NUD_IDLE;
			NUD_CHECK: nud_next_state = checksum_valid ? NUD_SEND_1 : NUD_CHECK;
			NUD_SEND_1: nud_next_state = ready_i ? NUD_SEND_2 : NUD_SEND_1;
			NUD_SEND_2: nud_next_state = ready_i ? NUD_IDLE : NUD_SEND_2;
			default: nud_next_state = NUD_IDLE;
		endcase
	end

    checksum_calculator checksum_calculator_NUD(
        .clk(clk),
        .rst_p(rst_p),
        .ip6_src(NS_o.ether.ip6.src),
        .ip6_dst(NS_o.ether.ip6.dst),
        .payload_length({16'd0, NS_o.ether.ip6.payload_len}),
        .next_header(NS_o.ether.ip6.next_hdr),
        .current_payload({NS_o.option, NS_o.icmpv6}),
        .mask(~(256'h0)),
        .is_first(1'b1),
        .ea_p(checksum_ea),
        .checksum(checksum_o),
        .valid(checksum_valid)
    );

    assign valid_o = (nud_state == NUD_SEND_1) || (nud_state == NUD_SEND_2);

endmodule

