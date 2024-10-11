/*
- Address configuration for the TanLabs project -
Function description:
- Takes in button push as control signal
    reset - reset all ip adresses
    btn[0] - next interface(0->1->2->3->0...), starting at the first 16-bit of the ip address
    btn[1] - accept current 16-bit on dip switches and continue to next 16-bit
                (if it's the last 16-bit, then set the ip address)

- input ports:
    clk - clock signal
    reset - reset signal
    btn - 4-bit button push signal
    dip_sw - 16-bit dip switch signal

- output ports:
    ip_addr - 128-bit ip address signal * 4 interfaces
    ip_addr_valid - 1-bit ip address validation signal * 4 interfaces (1 valid, 0 invalid)
*/

module address_config#(
    parameter dafault_mac_addr_0 = 48'h541069641f8c,
    parameter default_ipv6_addr_0 = 128'h541069feff641f8e00000000000080fe,
    parameter dafault_mac_addr_1 = 48'h541069641f8c,
    parameter default_ipv6_addr_1 = 128'h541069feff641f8e00000000000080fe,
    parameter dafault_mac_addr_2 = 48'h541069641f8c,
    parameter default_ipv6_addr_2 = 128'h541069feff641f8e00000000000080fe,
    parameter dafault_mac_addr_3 = 48'h541069641f8c,
    parameter default_ipv6_addr_3 = 128'h541069feff641f8e00000000000080fe
)
(
    input wire clk,
    input wire reset,

    input wire [3:0] btn,
    input wire [15:0] dip_sw,

    output wire [127:0] ip_addr_0,
    output wire [127:0] ip_addr_1,
    output wire [127:0] ip_addr_2,
    output wire [127:0] ip_addr_3,

    // validation signals
    output wire ip_addr_0_valid,
    output wire ip_addr_1_valid,
    output wire ip_addr_2_valid,
    output wire ip_addr_3_valid,

    // led signals
    output wire [15:0] led
);

    // internal signals
    // ip address register
    reg [127:0] ip_addr_reg_0; 
    reg [127:0] ip_addr_reg_1;
    reg [127:0] ip_addr_reg_2;
    reg [127:0] ip_addr_reg_3;

    // validation register
    reg ip_addr_0_valid_reg;
    reg ip_addr_1_valid_reg;
    reg ip_addr_2_valid_reg;
    reg ip_addr_3_valid_reg;
    
    reg [1:0] reading_interface; // current interface being read
    reg [2:0] reading_bit; // current bit being read

    // button signals
    reg [3:0] last_btn ; // last button signal
    wire[1:0] btn_shift; // shift button signal

    // shift button signal
    always_ff @(posedge clk)begin
        last_btn <= btn;
    end

    // shift button signal
    assign btn_shift[0] = last_btn[0] == 0 & btn[0] == 1;
    assign btn_shift[1] = last_btn[1] == 0 & btn[1] == 1;

    // button changes on interface and bit
    always @(posedge clk)begin
        if(reset)begin
            // reset all ip addresses
            ip_addr_reg_0 <= default_ipv6_addr_0;
            ip_addr_reg_1 <= default_ipv6_addr_1;
            ip_addr_reg_2 <= default_ipv6_addr_2;
            ip_addr_reg_3 <= default_ipv6_addr_3;
            // reset reading interface and bit
            reading_interface <= 2'b0;
            reading_bit <= 3'b0;
            // reset valid
            ip_addr_0_valid_reg <= 1;
            ip_addr_1_valid_reg <= 1;
            ip_addr_2_valid_reg <= 1;
            ip_addr_3_valid_reg <= 1;
        end
        else begin
            // btn[0] > btn[1], igonre btn[2] and btn[3]
            if (btn_shift[0])begin
                // next interface
                reading_interface <= reading_interface + 1;
                reading_bit <= 3'b0; // reset bit
            end
            else if (btn_shift[1])begin
                // accept current 16-bit on dip switches and continue to next 16-bit
                case (reading_interface)
                    2'b00: begin
                        case(reading_bit)
                            3'b000: ip_addr_reg_0[127:112] <= dip_sw;
                            3'b001: ip_addr_reg_0[111:96] <= dip_sw;
                            3'b010: ip_addr_reg_0[95:80] <= dip_sw;
                            3'b011: ip_addr_reg_0[79:64] <= dip_sw;
                            3'b100: ip_addr_reg_0[63:48] <= dip_sw;
                            3'b101: ip_addr_reg_0[47:32] <= dip_sw;
                            3'b110: ip_addr_reg_0[31:16] <= dip_sw;
                            3'b111: ip_addr_reg_0[15:0] <= dip_sw;
                        endcase
                    end
                    2'b01: begin
                        case(reading_bit)
                            3'b000: ip_addr_reg_1[127:112] <= dip_sw;
                            3'b001: ip_addr_reg_1[111:96] <= dip_sw;
                            3'b010: ip_addr_reg_1[95:80] <= dip_sw;
                            3'b011: ip_addr_reg_1[79:64] <= dip_sw;
                            3'b100: ip_addr_reg_1[63:48] <= dip_sw;
                            3'b101: ip_addr_reg_1[47:32] <= dip_sw;
                            3'b110: ip_addr_reg_1[31:16] <= dip_sw;
                            3'b111: ip_addr_reg_1[15:0] <= dip_sw;
                        endcase
                    end
                    2'b10: begin
                        case(reading_bit)
                            3'b000: ip_addr_reg_2[127:112] <= dip_sw;
                            3'b001: ip_addr_reg_2[111:96] <= dip_sw;
                            3'b010: ip_addr_reg_2[95:80] <= dip_sw;
                            3'b011: ip_addr_reg_2[79:64] <= dip_sw;
                            3'b100: ip_addr_reg_2[63:48] <= dip_sw;
                            3'b101: ip_addr_reg_2[47:32] <= dip_sw;
                            3'b110: ip_addr_reg_2[31:16] <= dip_sw;
                            3'b111: ip_addr_reg_2[15:0] <= dip_sw;
                        endcase
                    end
                    2'b11: begin
                        case(reading_bit)
                            3'b000: ip_addr_reg_3[127:112] <= dip_sw;
                            3'b001: ip_addr_reg_3[111:96] <= dip_sw;
                            3'b010: ip_addr_reg_3[95:80] <= dip_sw;
                            3'b011: ip_addr_reg_3[79:64] <= dip_sw;
                            3'b100: ip_addr_reg_3[63:48] <= dip_sw;
                            3'b101: ip_addr_reg_3[47:32] <= dip_sw;
                            3'b110: ip_addr_reg_3[31:16] <= dip_sw;
                            3'b111: ip_addr_reg_3[15:0] <= dip_sw;
                        endcase
                    end
                endcase
                // next 16 bits
                reading_bit <= reading_bit + 1;
                // set valid
                if(reading_bit == 3'b000)begin
                    // set ip address valid when all 16 bits are set
                    case(reading_interface)
                        2'b00: ip_addr_0_valid_reg <= 1;
                        2'b01: ip_addr_1_valid_reg <= 1;
                        2'b10: ip_addr_2_valid_reg <= 1;
                        2'b11: ip_addr_3_valid_reg <= 1;
                    endcase
                end else if (reading_bit == 3'b001)begin
                    // reset valid when not all 16 bits are set
                    case(reading_interface)
                        2'b00: ip_addr_0_valid_reg <= 0;
                        2'b01: ip_addr_1_valid_reg <= 0;
                        2'b10: ip_addr_2_valid_reg <= 0;
                        2'b11: ip_addr_3_valid_reg <= 0;
                    endcase
                end
            end
        end
    end

    // assign ip address
    assign ip_addr_0 = ip_addr_reg_0;
    assign ip_addr_1 = ip_addr_reg_1;
    assign ip_addr_2 = ip_addr_reg_2;
    assign ip_addr_3 = ip_addr_reg_3;

    // assign ip address valid
    assign ip_addr_0_valid = ip_addr_0_valid_reg;
    assign ip_addr_1_valid = ip_addr_1_valid_reg;
    assign ip_addr_2_valid = ip_addr_2_valid_reg;
    assign ip_addr_3_valid = ip_addr_3_valid_reg;

    // assign led
    reg [15:0] led_reg;
    // 15-8: interface, 7-0: bit
    always @(posedge clk)begin
        case(reading_interface)
            2'b00: led_reg[15:8] <= 8'b00000001;
            2'b01: led_reg[15:8] <= 8'b00000010;
            2'b10: led_reg[15:8] <= 8'b00000100;
            2'b11: led_reg[15:8] <= 8'b00001000;
        endcase

        case(reading_bit)
            3'b000: led_reg[7:0] <= 8'b00000001;
            3'b001: led_reg[7:0] <= 8'b00000010;
            3'b010: led_reg[7:0] <= 8'b00000100;
            3'b011: led_reg[7:0] <= 8'b00001000;
            3'b100: led_reg[7:0] <= 8'b00010000;
            3'b101: led_reg[7:0] <= 8'b00100000;
            3'b110: led_reg[7:0] <= 8'b01000000;
            3'b111: led_reg[7:0] <= 8'b10000000;
        endcase
    end

    assign led = led_reg;

endmodule