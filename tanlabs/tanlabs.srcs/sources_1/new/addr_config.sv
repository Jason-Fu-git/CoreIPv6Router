`timescale 1ns / 1ps


module addr_config#(
    parameter default_mac_addr = 48'h000000000000,
    parameter default_ipv6_addr = 128'h00000000000000000000000000000000
)(
    input wire clk,
    input wire rst,
    input wire [ 47:0] new_mac_addr,
    input wire [127:0] new_ipv6_addr,
    input wire set_mac_addr,
    input wire set_ipv6_addr,
    output reg [ 47:0] mac_addr,
    output reg [127:0] ipv6_addr
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            mac_addr <= default_mac_addr;
            ipv6_addr <= default_ipv6_addr;
        end else begin
            if (set_mac_addr) begin
                mac_addr <= new_mac_addr;
            end
            if (set_ipv6_addr) begin
                ipv6_addr <= new_ipv6_addr;
            end
        end
    end
endmodule


module addr_controller(
    input wire clk,
    input wire rst,
    input wire [ 47:0] new_mac_addr,
    input wire [127:0] new_ipv6_addr,
    input wire set,
    input wire set_mac, // set_mac = 1, set_ipv6 = 0
    input wire [  1:0] index, // 0, 1, 2, 3
    output reg [ 47:0] mac_addr_out  [0:3],
    output reg [127:0] ipv6_addr_out [0:3]
    );
    reg set_mac_addr  [0:3];
    reg set_ipv6_addr [0:3];

    always_comb begin
        for (int i = 0; i < 4; i++) begin
            set_mac_addr[i]  = (set && set_mac    && (index == i));
            set_ipv6_addr[i] = (set && (!set_mac) && (index == i));
        end
    end

    addr_config #(.default_mac_addr(48'h541069641f8c), .default_ipv6_addr(128'h541069feff641f8e00000000000080fe)) addr_config_0(
        .clk(clk),
        .rst(rst),
        .new_mac_addr(new_mac_addr),
        .new_ipv6_addr(new_ipv6_addr),
        .set_mac_addr(set_mac_addr[0]),
        .set_ipv6_addr(set_ipv6_addr[0]),
        .mac_addr(mac_addr_out[0]),
        .ipv6_addr(ipv6_addr_out[0])
    );
    addr_config #(.default_mac_addr(48'h551069641f8c), .default_ipv6_addr(128'h551069feff641f8e00000000000080fe)) addr_config_1(
        .clk(clk),
        .rst(rst),
        .new_mac_addr(new_mac_addr),
        .new_ipv6_addr(new_ipv6_addr),
        .set_mac_addr(set_mac_addr[1]),
        .set_ipv6_addr(set_ipv6_addr[1]),
        .mac_addr(mac_addr_out[1]),
        .ipv6_addr(ipv6_addr_out[1])
    );
    addr_config #(.default_mac_addr(48'h561069641f8c), .default_ipv6_addr(128'h561069feff641f8e00000000000080fe)) addr_config_2(
        .clk(clk),
        .rst(rst),
        .new_mac_addr(new_mac_addr),
        .new_ipv6_addr(new_ipv6_addr),
        .set_mac_addr(set_mac_addr[2]),
        .set_ipv6_addr(set_ipv6_addr[2]),
        .mac_addr(mac_addr_out[2]),
        .ipv6_addr(ipv6_addr_out[2])
    );
    addr_config #(.default_mac_addr(48'h571069641f8c), .default_ipv6_addr(128'h571069feff641f8e00000000000080fe)) addr_config_3(
        .clk(clk),
        .rst(rst),
        .new_mac_addr(new_mac_addr),
        .new_ipv6_addr(new_ipv6_addr),
        .set_mac_addr(set_mac_addr[3]),
        .set_ipv6_addr(set_ipv6_addr[3]),
        .mac_addr(mac_addr_out[3]),
        .ipv6_addr(ipv6_addr_out[3])
    );
endmodule
