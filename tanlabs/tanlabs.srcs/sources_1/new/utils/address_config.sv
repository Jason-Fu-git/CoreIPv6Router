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

module address_config #(
    parameter dafault_mac_addr_0  = 48'h541069641f8c,
    parameter default_ipv6_addr_0 = 128'h541069feff641f8e00000000000080fe,
    parameter dafault_mac_addr_1  = 48'h551069641f8c,
    parameter default_ipv6_addr_1 = 128'h551069feff641f8e00000000000080fe,
    parameter dafault_mac_addr_2  = 48'h561069641f8c,
    parameter default_ipv6_addr_2 = 128'h561069feff641f8e00000000000080fe,
    parameter dafault_mac_addr_3  = 48'h571069641f8c,
    parameter default_ipv6_addr_3 = 128'h571069feff641f8e00000000000080fe
) (
    input wire clk,
    input wire reset,

    input wire [ 3:0] btn,
    input wire [15:0] dip_sw,

    output wire [3:0][127:0] ip_addr,
    output wire [3:0][ 47:0] mac_addr,

    // led signals
    output wire [15:0] led
);

  // internal signals
  // ip address register
  reg [3:0][127:0] ip_addr_reg;

  reg [3:0][47:0] mac_addr_reg;

  reg [1:0] reading_interface;  // current interface being read
  reg [2:0] reading_bit;  // current bit being read
  reg state;  // 0 -> ipv6, 1 -> mac

  // button signals
  reg [3:0] last_btn;  // last button signal
  wire [2:0] btn_shift;  // shift button signal

  // shift button signal
  always_ff @(posedge clk) begin
    last_btn <= btn;
  end

  // shift button signal
  assign btn_shift[0] = last_btn[0] == 0 & btn[0] == 1;
  assign btn_shift[1] = last_btn[1] == 0 & btn[1] == 1;
  assign btn_shift[2] = last_btn[2] == 0 & btn[2] == 1;

  // button changes on interface and bit
  always @(posedge clk) begin
    if (reset) begin
      // reset all ip addresses
      ip_addr_reg[0] <= default_ipv6_addr_0;
      ip_addr_reg[1] <= default_ipv6_addr_1;
      ip_addr_reg[2] <= default_ipv6_addr_2;
      ip_addr_reg[3] <= default_ipv6_addr_3;
      // reset all mac addresses
      mac_addr_reg[0] <= dafault_mac_addr_0;
      mac_addr_reg[1] <= dafault_mac_addr_1;
      mac_addr_reg[2] <= dafault_mac_addr_2;
      mac_addr_reg[3] <= dafault_mac_addr_3;
      // reset reading interface and bit
      reading_interface <= 2'b0;
      reading_bit <= 3'b0;
      // reset state
      state <= 1'b0;
    end else begin
      // btn[2]->btn[0] > btn[1], 
      if (btn_shift[2]) begin
        reading_interface <= 2'b0;
        reading_bit <= 3'b0;
        state <= ~state;
      end else if (btn_shift[0]) begin
        // next interface
        reading_interface <= reading_interface + 1;
        reading_bit <= 3'b0;  // reset bit
      end else if (btn_shift[1]) begin
        // accept current 16-bit on dip switches and continue to next 16-bit
        case (state)
          0: begin
            case (reading_bit)
              3'b000: ip_addr_reg[reading_interface][127:112] <= dip_sw;
              3'b001: ip_addr_reg[reading_interface][111:96] <= dip_sw;
              3'b010: ip_addr_reg[reading_interface][95:80] <= dip_sw;
              3'b011: ip_addr_reg[reading_interface][79:64] <= dip_sw;
              3'b100: ip_addr_reg[reading_interface][63:48] <= dip_sw;
              3'b101: ip_addr_reg[reading_interface][47:32] <= dip_sw;
              3'b110: ip_addr_reg[reading_interface][31:16] <= dip_sw;
              3'b111: ip_addr_reg[reading_interface][15:0] <= dip_sw;
            endcase

            // next 16 bits
            reading_bit <= reading_bit + 1;
          end
          1: begin
            case (reading_bit)
              3'b000:  mac_addr_reg[reading_interface][47:32] <= dip_sw;
              3'b001:  mac_addr_reg[reading_interface][31:16] <= dip_sw;
              3'b010:  mac_addr_reg[reading_interface][15:0] <= dip_sw;
              default: mac_addr_reg[reading_interface][47:0] <= dafault_mac_addr_0;
            endcase

            // next 16 bits
            if (reading_bit != 3'b010) begin
              reading_bit <= reading_bit + 1;
            end else begin
              reading_bit <= 3'b000;
            end
          end
        endcase
      end
    end
  end

  // assign ip address
  assign ip_addr  = ip_addr_reg;

  // assign mac address
  assign mac_addr = mac_addr_reg;

  // assign led
  reg [15:0] led_reg;
  // 15-8: interface, 7-0: bit
  always @(posedge clk) begin
    case (reading_interface)
      2'b00: led_reg[15:8] <= 8'b00000001;
      2'b01: led_reg[15:8] <= 8'b00000010;
      2'b10: led_reg[15:8] <= 8'b00000100;
      2'b11: led_reg[15:8] <= 8'b00001000;
    endcase

    case (reading_bit)
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
