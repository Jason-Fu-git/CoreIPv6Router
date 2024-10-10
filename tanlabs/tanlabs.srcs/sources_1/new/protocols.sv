`timescale 1ns / 1ps

`include "frame_datapath.vh"

module datapath_sm(
    input wire clk,
    input wire rst,
    
    input frame_beat in, // input pack
    input wire s_ready, // `in` is valid
    output reg in_ready, // ready to fetch another pack

    output frame_beat out, // output pack
    // No `out_valid` here because `out.valid` makes it redundant
    input wire out_ready, // output pack can be sent

    input wire [ 47:0] mac_addrs  [0:3],
    input wire [127:0] ipv6_addrs [0:3]
    );

    always_comb begin
        in_ready = ((state == DP_IDLE) || ((state == DP_ND) && (nd_state == ND_1)));
    end

    typedef enum logic [3:0] {
        DP_IDLE, // IDLE is not only waiting for the first pack, but also transferring all packs if not being the first.
        DP_ND
    } dp_state_t;

    dp_state_t state, next_state;

    // state transition
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= DP_IDLE;
        end else begin
            state <= next_state;
        end
    end

    frame_beat first_beat;

    ether_hdr in_ether_hdr;
    ip6_hdr in_ip6_hdr;

    assign in_ether_hdr = first_beat.data;
    assign in_ip6_hdr = first_beat.data.ip6;

    NS_packet NS_packet_i;

    logic [15:0] NS_checksum;
    reg NS_checksum_OK;
    // assign NS_checksum_OK = (NS_checksum == 16'h0);
    logic NS_checksum_ea;
    logic NS_checksum_valid;
    // assign NS_checksum_valid = 1'b1;
    // assign NS_checksum_OK = 1'b1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            NS_checksum_OK <= 1'b0;
        end else begin
            if (NS_checksum_valid) begin
                NS_checksum_OK <= (NS_checksum == 16'hffff);
            end
            if (state != DP_ND) begin
                NS_checksum_OK <= 1'b0;
            end
        end
    end

    checksum_calculator checksum_calculator_i_NS(
        .clk(clk),
        .rst_p(rst),
        .ip6_src(NS_packet_i.ether.ip6.src),
        .ip6_dst(NS_packet_i.ether.ip6.dst),
        .payload_length({16'd0, NS_packet_i.ether.ip6.payload_len}),
        .next_header(NS_packet_i.ether.ip6.next_hdr),
        //.current_payload_length({16'd0, {NS_packet_i.ether.ip6.payload_len[7:0], NS_packet_i.ether.ip6.payload_len[15:8]}}),
        .current_payload({NS_packet_i.option, NS_packet_i.icmpv6}),
        .mask(~(256'h0)),
        .is_first(1'b1),
        .ea_p(NS_checksum_ea),
        .checksum(NS_checksum),
        .valid(NS_checksum_valid)
    );

    logic [7:0] NS_option_len;
    assign NS_option_len = NS_packet_i.option.len;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            NS_packet_i <= 0;
            NS_checksum_ea <= 1'b0;
        end else begin
            if ((nd_state == ND_1) && (nd_next_state == ND_2)) begin
                NS_packet_i <= {in.data, first_beat.data};
                NS_checksum_ea <= 1'b1;
                NA_checksum_ea <= 1'b1;
            end else if ((nd_state == ND_3) && (nd_next_state != ND_3)) begin
                NS_checksum_ea <= 1'b0;
            end else if ((nd_state == ND_last) && (nd_next_state != ND_last)) begin
                NA_checksum_ea <= 1'b0;
            end
        end
    end

    logic NS_valid;
    assign NS_valid = ((NS_option_len > 0) && (NS_packet_i.icmpv6.target_addr[7:0] != 8'hff) && NS_checksum_OK);

    logic [2:0] in_meta_dst;
    logic [2:0] in_meta_src;
    assign in_meta_dst = first_beat.meta.dest;
    assign in_meta_src = first_beat.meta.id;

    NA_packet NA_packet_i;
    logic [15:0] NA_checksum;
    // assign NA_checksum = 16'd60000;
    logic NA_checksum_valid;
    // assign NA_checksum_valid = 1'b1;
    logic NA_checksum_ea;

    checksum_calculator checksum_calculator_i_NA(
        .clk(clk),
        .rst_p(rst),
        .ip6_src(NA_packet_i.ether.ip6.src),
        .ip6_dst(NA_packet_i.ether.ip6.dst),
        .payload_length({16'd0, NA_packet_i.ether.ip6.payload_len}),
        .next_header(NA_packet_i.ether.ip6.next_hdr),
        //.current_payload_length({16'd0, NA_packet_i.ether.ip6.payload_len}),
        .current_payload({NA_packet_i.option, NA_packet_i.icmpv6}),
        .mask(~(256'h0)),
        .is_first(1'b1),
        .ea_p(NA_checksum_ea),
        .checksum(NA_checksum),
        .valid(NA_checksum_valid)
    );

    always_comb begin
        NA_packet_i.option.option_type = 8'd2;
        NA_packet_i.option.len = 8'd1;
        //NA_packet_i.option.mac_addr = mac_addrs[in_meta_dst[1:0]];
        NA_packet_i.icmpv6.icmpv6_type = ICMPv6_HDR_TYPE_NA; //8'd136
        NA_packet_i.icmpv6.code = 8'd0;
        //NA_packet_i.icmpv6.checksum = NA_checksum;
        NA_packet_i.icmpv6.checksum = 0;
        NA_packet_i.icmpv6.R = 1'b1; // sent from router
        NA_packet_i.icmpv6.S = 1'b1; // TODO: set the flag, now is default: sent as response to NS
        NA_packet_i.icmpv6.O = 1'b0; // TODO: set the flag
        NA_packet_i.icmpv6.reserved_lo = 24'h0;
        NA_packet_i.icmpv6.reserved_hi = 5'h0;
        NA_packet_i.icmpv6.target_addr = in_ip6_hdr.src;
        NA_packet_i.ether.dst = in_ether_hdr.src;
        //NA_packet_i.ether.src = mac_addrs[in_meta_dst[1:0]];
        NA_packet_i.ether.ethertype = 16'hdd86; // IPv6
        NA_packet_i.ether.ip6.dst = in_ip6_hdr.src;
        //NA_packet_i.ether.ip6.src = ipv6_addrs[in_meta_dst[1:0]];
        NA_packet_i.ether.ip6.next_hdr = IP6_HDR_TYPE_ICMPv6; // 8'd58
        NA_packet_i.ether.ip6.hop_limit = IP6_HDR_HOP_LIMIT_DEFAULT; // 8'd255
        NA_packet_i.ether.ip6.payload_len = {8'd32, 8'd0}; // 24 bytes for ICMPv6 header, 8 bytes for option
        NA_packet_i.ether.ip6.flow_lo = 24'b0;
        NA_packet_i.ether.ip6.flow_hi = 4'b0;
        NA_packet_i.ether.ip6.version = 4'd6;
        case (in_meta_dst[1:0])
            2'd0: begin
                NA_packet_i.option.mac_addr = mac_addrs[0];
                NA_packet_i.ether.src = mac_addrs[0];
                NA_packet_i.ether.ip6.src = ipv6_addrs[0];
            end
            2'd1: begin
                NA_packet_i.option.mac_addr = mac_addrs[1];
                NA_packet_i.ether.src = mac_addrs[1];
                NA_packet_i.ether.ip6.src = ipv6_addrs[1];
            end
            2'd2: begin
                NA_packet_i.option.mac_addr = mac_addrs[2];
                NA_packet_i.ether.src = mac_addrs[2];
                NA_packet_i.ether.ip6.src = ipv6_addrs[2];
            end
            2'd3: begin
                NA_packet_i.option.mac_addr = mac_addrs[3];
                NA_packet_i.ether.src = mac_addrs[3];
                NA_packet_i.ether.ip6.src = ipv6_addrs[3];
            end
        endcase
    end

    // handle ND

    typedef enum logic [2:0] {
        ND_IDLE,
        ND_1,
        ND_2,
        ND_3,
        ND_4,
        ND_last
    } ND_state_t;

    ND_state_t nd_state, nd_next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            
        end else begin
            if ((state == DP_ND) && (nd_state == ND_1)) begin // construct the first pack of NA
                out.data <= NA_packet_i[447:0]; // 56 bytes
                out.is_first <= 1'b1;
                out.last <= 1'b0; // Not the last pack
                out.valid <= 1'b0; // Wait for ND_2 to send
                out.keep <= 56'hffffffffffffff; // full pack
                out.meta.dont_touch <= 1'b0;
                out.meta.drop_next <= 1'b0;
                out.meta.dest <= in_meta_src;
                out.meta.id <= in_meta_dst;
            end else if ((state == DP_ND) && (nd_state == ND_3)) begin // send the first pack of NA
                out.valid <= 1'b1;
                out.meta.drop <= !NS_valid;
                // out.meta.drop <= 1'b0; // DEBUG: send NA even if NS is not valid
            end else if ((state == DP_ND) && (nd_state == ND_last)) begin // construct & send the second pack of NA
                out.data <= {208'h0, NA_packet_i[687:448]}; // 86 - 56 = 30 bytes
                out.data[15:0] <= ~{NA_checksum[7:0], NA_checksum[15:8]};
                out.is_first <= 1'b0;
                out.last <= 1'b1; // The last pack
                out.valid <= 1'b1; // Send directly
                out.keep <= 56'h0000003fffffff; // 30 bytes valid: 0b...11_1111_1111_1111_1111_1111_1111_1111
                out.meta.dont_touch <= 1'b0;
                out.meta.drop_next <= 1'b0;
                out.meta.dest <= in_meta_src;
                out.meta.id <= in_meta_dst;
            end else begin
                out.valid <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            nd_state <= ND_IDLE;
        end else begin
            nd_state <= nd_next_state;
        end
    end

    always_comb begin
        case (nd_state)
            ND_IDLE: begin
                nd_next_state = ((next_state == DP_ND) ? ND_1 : ND_IDLE);
            end
            ND_1: begin
                nd_next_state = (s_ready ? ND_2 : ND_1);
            end
            ND_2: begin
                nd_next_state = (NS_checksum_valid ? ND_3 : ND_2);
            end
            ND_3: begin
                nd_next_state = (out_ready ? ND_4 : ND_3);
            end
            ND_4: begin
                nd_next_state = (NA_checksum_valid ? ND_last : ND_4);
            end
            ND_last: begin
                nd_next_state = (out_ready ? ND_IDLE : ND_last);
            end
        endcase
    end

    // prepare the first beat for other states
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            first_beat <= 0;
        end else begin
            if ((state == DP_IDLE) && (next_state != DP_IDLE)) begin // getting the first pack
                first_beat <= in;
            end
        end
    end

    // state transition, checking conditions inside
    always_comb begin
        case (state)
            DP_IDLE: begin
                if (!s_ready || !in.is_first) begin
                    next_state = DP_IDLE;
                end else begin
                    if (
                        (in.data.ip6.next_hdr == IP6_HDR_TYPE_ICMPv6)
                        && (in.data.ip6.p[7:0] == ICMPv6_HDR_TYPE_NS)
                        && (in.data.ip6.hop_limit == IP6_HDR_HOP_LIMIT_DEFAULT)
                        && (in.data.ip6.p[15:8] == 0)
                        && ({in.data.ip6.payload_len[7:0], in.data.ip6.payload_len[15:8]} >= 16'd24)
                        && (in.data.ip6.payload_len[2:0] == 3'b000)
                        && (in.data.ip6.src != 0)
                    ) begin
                        next_state = DP_ND;
                    end else begin
                        next_state = DP_IDLE;
                    end
                end
            end
            DP_ND: begin
                next_state = ((nd_state == ND_last) && (nd_next_state == ND_IDLE)) ? DP_IDLE : DP_ND;
            end
            default: begin
                next_state = DP_IDLE;
            end
        endcase
    end

endmodule
