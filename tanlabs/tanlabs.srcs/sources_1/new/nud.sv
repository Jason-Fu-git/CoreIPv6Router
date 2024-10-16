`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/14 19:51:49
// Design Name: 
// Module Name: nud
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "frame_datapath.vh"

module nud(
    input  wire          clk       ,
    input  wire          rst       ,
    input  wire          we_i      , // needed to send NS, trigger
    input  logic [127:0] tgt_addr_i, // target address
    input  logic [127:0] ip6_addr_i, // self IPv6 address
    input  logic [ 47:0] mac_addr_i, // self MAC address
    input  logic [  1:0] iface_i   , // interface ID (0, 1, 2, 3)
    input  logic         ack_i     , // NS sent by datapath
    output NS_packet     NS_o      , // NS packet to be sent by datapath
    output logic         NS_valid_o, // NS ready, should be sent by datapath
    output logic [  1:0] iface_o   , // interface ID (0, 1, 2, 3)
    output logic [ 15:0] checksum_o  // checksum of NS packet
);

    logic we;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            we <= 1'b0;
        end else begin
            if (we_i && !we) begin
                we <= 1'b1;
            end else if (ack_i) begin
                we <= 1'b0;
            end
        end
    end

    logic [127:0] sn_addr; // solicited-node address
    logic [127:0] tgt_addr;
    logic [127:0] ip6_addr;
    logic [ 47:0] mac_addr;
    logic [  1:0] iface;

    assign iface_o = iface;

    always_comb begin
        sn_addr[103:0] = {104'h010000000000000000000002ff};
        // sn_addr[127:104] = tgt_addr_i[127:104];
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sn_addr[127:104] <= 24'b0;
            tgt_addr <= 128'b0;
            ip6_addr <= 128'b0;
            mac_addr <= 48'b0;
            iface <= 2'b0;
        end else begin
            if (we_i) begin
                sn_addr[127:104] <= tgt_addr_i[127:104];
                tgt_addr <= tgt_addr_i;
                ip6_addr <= ip6_addr_i;
                mac_addr <= mac_addr_i;
                iface <= iface_i;
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

    logic checksum_valid;

    checksum_calculator checksum_calculator_i_NUD(
        .clk(clk),
        .rst_p(rst),
        .ip6_src(NS_o.ether.ip6.src),
        .ip6_dst(NS_o.ether.ip6.dst),
        .payload_length({16'd0, NS_o.ether.ip6.payload_len}),
        .next_header(NS_o.ether.ip6.next_hdr),
        .current_payload({NS_o.option, NS_o.icmpv6}),
        .mask(~(256'h0)),
        .is_first(1'b1),
        .ea_p(we),
        .checksum(checksum_o),
        .valid(checksum_valid)
    );

    assign NS_valid_o = we && checksum_valid;

endmodule
