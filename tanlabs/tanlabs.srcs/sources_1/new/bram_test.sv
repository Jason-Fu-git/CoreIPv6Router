`timescale 1ns / 1ps

// module vctrie #(
//     parameter width,
//     parameter depth,
//     parameter bin_size,
//     parameter addr_width
// ) (
//     input wire clk,
//     input wire rst_p
// );
    
// endmodule

module bram_test(
);

    reg clk;

    // bram_0
    // width 54 depth 256 entry 1 address 8
    
    logic [ 7:0] addra_0;
    logic [53:0] dina_0;
    logic [53:0] douta_0;
    logic ena_0;
    logic wea_0;
    
    blk_mem_gen_0 bram_0(
        .addra(addra_0),
        .clka(clk),
        .dina(dina_0),
        .douta(douta_0),
        .ena(ena_0),
        .wea(wea_0)
    );

    initial begin
        clk = 1;
        addra_0 = 0;
        dina_0 = 0;
        ena_0 = 1;
        wea_0 = 1;

        for (int i = 0; i < 256; i = i + 1) begin
            #8
            addra_0 = i;
            dina_0 = i;
            wea_0 = 1;
            ena_0 = 1;
        end

        for (int i = 0; i < 256; i = i + 1) begin
            #8
            addra_0 = i;
            wea_0 = 0;
            ena_0 = 1;
        end
    end

    clock clock_i(.clk_125M(clk));

    // bram_1
    // width 594 depth 256 entry 15 address 8


    // bram_2
    // width 612 depth 12288 entry 15 address 14


    // bram_3
    // width 612 depth 12288 entry 15 address 14


    // bram_4
    // width 612 depth 10240 entry 15 address 14


    // bram_5
    // width 450 depth 10240 entry 11 address 14


    // bram_6
    // width 216 depth 8192 entry 5 address 13


    // bram_7
    // width 216 depth 8192 entry 5 address 13


    // bram_8
    // width 216 depth 8192 entry 5 address 13


    // bram_9
    // width 216 depth 8192 entry 5 address 13


    // bram_10
    // width 216 depth 8192 entry 5 address 13


    // bram_11
    // width 216 depth 8192 entry 5 address 13


    // bram_12
    // width 216 depth 8192 entry 5 address 13


    // bram_13
    // width 216 depth 8192 entry 5 address 13


    // bram_14
    // width 216 depth 8192 entry 5 address 13


    // bram_15
    // width 216 depth 8192 entry 5 address 13

endmodule
