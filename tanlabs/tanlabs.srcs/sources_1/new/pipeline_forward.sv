module pipeline_forward(
    input wire clk,
    input wire rst_p,

    input wire in_valid ,
    input wire out_ready,
    output reg out_valid,
    output reg in_ready,

    input  frame_beat in,
    output frame_beat out
);


endmodule;

