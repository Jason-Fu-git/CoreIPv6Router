`timescale 1ps / 1ps

module tb_frame_datapath
#(
    parameter DATA_WIDTH = 64,
    parameter ID_WIDTH = 3
)
(

);
    //added for ip configuration
    reg [127:0] ip_addrs[3:0];
    reg [ 47:0] mac_addrs[3:0];
    reg ip_valid[3:0];
    reg reset;
    initial begin
        // set ip addr 0
        ip_addrs[0] = 128'h051069feff641f8e00000000000080fe;
        ip_valid[0] = 1;
        mac_addrs[0] = 48'h541069641f8c;
        ip_addrs[1] = 128'h061069feff641f8e00000000000080fe;
        ip_valid[1] = 1;
        mac_addrs[1] = 48'h551069641f8c;
        ip_addrs[2] = 128'h071069feff641f8e00000000000080fe;
        ip_valid[2] = 1;
        mac_addrs[2] = 48'h561069641f8c;
        ip_addrs[3] = 128'h081069feff641f8e00000000000080fe;
        ip_valid[3] = 1;
        mac_addrs[3] = 48'h571069641f8c;
        reset = 1;
        #6000
        reset = 0;
    end

    wire clk_125M;

    clock clock_i(
        .clk_125M(clk_125M)
    );

    wire [DATA_WIDTH - 1:0] in_data;
    wire [DATA_WIDTH / 8 - 1:0] in_keep;
    wire in_last;
    wire [DATA_WIDTH / 8 - 1:0] in_user;
    wire [ID_WIDTH - 1:0] in_id;
    wire in_valid;
    wire in_ready;

    axis_model axis_model_i(
        .clk(clk_125M),
        .reset(reset),

        .m_data(in_data),
        .m_keep(in_keep),
        .m_last(in_last),
        .m_user(in_user),
        .m_id(in_id),
        .m_valid(in_valid),
        .m_ready(in_ready)
    );

    wire [DATA_WIDTH - 1:0] out_data;
    wire [DATA_WIDTH / 8 - 1:0] out_keep;
    wire out_last;
    wire [DATA_WIDTH / 8 - 1:0] out_user;
    wire [ID_WIDTH - 1:0] out_dest;
    wire out_valid;
    wire out_ready;

    // README: Instantiate your datapath.
    frame_datapath dut(
        .eth_clk(clk_125M),
        .reset(reset),

        .s_data(in_data),
        .s_keep(in_keep),
        .s_last(in_last),
        .s_user(in_user),
        .s_id(in_id),
        .s_valid(in_valid),
        .s_ready(in_ready),

        .m_data(out_data),
        .m_keep(out_keep),
        .m_last(out_last),
        .m_user(out_user),
        .m_dest(out_dest),
        .m_valid(out_valid),
        .m_ready(out_ready),

        .ip_addr_0(ip_addrs[0]),
        .ip_valid_0(ip_valid[0]),
        .mac_addr_0(mac_addrs[0]),
        .ip_addr_1(ip_addrs[1]),
        .ip_valid_1(ip_valid[1]),
        .mac_addr_1(mac_addrs[1]),
        .ip_addr_2(ip_addrs[2]),
        .ip_valid_2(ip_valid[2]),
        .mac_addr_2(mac_addrs[2]),
        .ip_addr_3(ip_addrs[3]),
        .ip_valid_3(ip_valid[3]),
        .mac_addr_3(mac_addrs[3])
    );

    axis_receiver axis_receiver_i(
        .clk(clk_125M),
        .reset(reset),

        .s_data(out_data),
        .s_keep(out_keep),
        .s_last(out_last),
        .s_user(out_user),
        .s_dest(out_dest),
        .s_valid(out_valid),
        .s_ready(out_ready)
    );
endmodule
