`timescale 1ns / 1ps

module tb_trie8;

    logic clk = 0;
    logic rst_p;

    logic [127:0] pipeline_prefix = 0;  // TODO: pipeline_prefix is file input
    logic error;

  // ===========================
  // Trie8
  // ===========================
    // fixed params
    parameter tb_VC_ENTRY_SIZE   = 38;
    parameter tb_VC_LEN_WIDTH    = 5;
    parameter tb_BT_ADDR_WIDTH   = 10;
    parameter tb_BT_NODE_WIDTH   = 36;
    parameter tb_OFFSET_WIDTH    = 5;
    parameter tb_IP6_WIDTH       = 128;
    parameter tb_MATCH_LEN_WIDTH = 8;
    
    // trie params
    parameter M_VC_ADDR_WIDTH = 13;
    // parameter M_VC_NEXT_ADDR_WIDTH = 13;
    parameter M_VC_BIN_SIZE = 15;
    parameter M_VC_NODE_WIDTH = M_VC_BIN_SIZE * tb_VC_ENTRY_SIZE + 2 * M_VC_ADDR_WIDTH;
    parameter [3:0] tb_VC_ADDR_WIDTH [0:16] = {4'd8, 4'd13, 4'd13, 4'd13, 4'd13, 4'd12, 4'd8, 4'd8, 4'd8, 4'd8, 4'd8, 4'd8, 4'd8, 4'd8, 4'd8, 4'd8, 0};
    parameter [3:0] tb_VC_BIN_SIZE   [0:15] = {4'd1, 4'd7,  4'd15, 4'd15, 4'd14, 4'd10, 4'd1, 4'd1, 4'd1, 4'd1, 4'd1, 4'd1, 4'd1, 4'd1, 4'd1, 4'd1};

	// pipeline signals
	frame_beat [15:0]                 frame_beat_i; // Change
	logic      [15:0]                 in_valid; // Change
	logic      [15:0]                 out_ready;
	frame_beat [15:0]                 frame_beat_o;
	logic      [15:0]                 in_ready;
	logic      [15:0]                 out_valid;

	// VCTrie BRAM controller signals
	logic [15:0][  M_VC_ADDR_WIDTH-1:0] vc_addr_o;
	logic [15:0][  M_VC_NODE_WIDTH-1:0] vc_node_i;

	// VCTrie registers between pipelines
	logic [15:0][   M_VC_ADDR_WIDTH-1:0] vc_init_addr_i;
	logic [15:0][tb_MATCH_LEN_WIDTH-1:0] vc_max_match_i;
	logic [15:0][      tb_IP6_WIDTH-1:0] vc_remaining_prefix_i;
	logic [15:0][   tb_OFFSET_WIDTH-1:0] vc_next_hop_offset_i;
	logic [15:0][   M_VC_ADDR_WIDTH-1:0] vc_init_addr_o;
	logic [15:0][tb_MATCH_LEN_WIDTH-1:0] vc_max_match_o;
	logic [15:0][      tb_IP6_WIDTH-1:0] vc_remaining_prefix_o;
	logic [15:0][   tb_OFFSET_WIDTH-1:0] vc_next_hop_offset_o;

	// BTrie BRAM controller signals
	logic [15:0][  tb_BT_ADDR_WIDTH-1:0] bt_addr_o;
	logic [15:0][  tb_BT_NODE_WIDTH-1:0] bt_node_i;

	// BTrie registers between pipelines
	logic [15:0][  tb_BT_ADDR_WIDTH-1:0] bt_init_addr_i;
	logic [15:0][tb_MATCH_LEN_WIDTH-1:0] bt_max_match_i;
	logic [15:0][      tb_IP6_WIDTH-1:0] bt_remaining_prefix_i;
	logic [15:0][   tb_OFFSET_WIDTH-1:0] bt_next_hop_offset_i;
	logic [15:0][  tb_BT_ADDR_WIDTH-1:0] bt_init_addr_o;
	logic [15:0][tb_MATCH_LEN_WIDTH-1:0] bt_max_match_o;
	logic [15:0][      tb_IP6_WIDTH-1:0] bt_remaining_prefix_o;
	logic [15:0][   tb_OFFSET_WIDTH-1:0] bt_next_hop_offset_o;

  // ===========================
  // Block RAMs
  // ===========================

  logic web[16];
  logic [12:0] addrb[16];
  logic [35:0] dinb[16];
  logic [35:0] doutb[16];

  // input
  always_ff @(posedge clk) begin : PinelineInput
    if (rst_p) begin
      vc_max_match_i[0] <= 0;
      vc_next_hop_offset_i[0] <= 0;
      bt_max_match_i[0] <= 0;
      bt_next_hop_offset_i[0] <= 0;
      vc_init_addr_i[0] <= 0;
      bt_init_addr_i[0] <= 0;
      vc_remaining_prefix_i[0] <= 0;
      bt_remaining_prefix_i[0] <= 0;
    end else begin
      if (in_ready[0]) begin
        vc_max_match_i[0] <= 0;
        vc_next_hop_offset_i[0] <= 0;
        bt_max_match_i[0] <= 0;
        bt_next_hop_offset_i[0] <= 0;
        vc_init_addr_i[0] <= 0;
        bt_init_addr_i[0] <= 0;
        vc_remaining_prefix_i[0] <= 0;
        bt_remaining_prefix_i[0] <= pipeline_prefix;
      end
    end
  end

  genvar i;
  // link the pipeline
  generate
    for (i = 0; i < 15; i = i + 1) begin : g_links
      assign frame_beat_i[i+1] = frame_beat_o[i];
      assign in_valid[i+1] = out_valid[i];
      assign out_ready[i] = in_ready[i+1];
      assign vc_init_addr_i[i+1] = vc_init_addr_o[i];
	  assign vc_max_match_i[i+1] = vc_max_match_o[i];
      assign vc_remaining_prefix_i[i+1] = vc_remaining_prefix_o[i];
      assign vc_next_hop_offset_i[i+1] = vc_next_hop_offset_o[i];
      assign bt_init_addr_i[i+1] = bt_init_addr_o[i];
	  assign bt_max_match_i[i+1] = bt_max_match_o[i];
      assign bt_remaining_prefix_i[i+1] = bt_remaining_prefix_o[i];
      assign bt_next_hop_offset_i[i+1] = bt_next_hop_offset_o[i];
    end
  endgenerate

  assign out_ready[15] = 1;

  // Instantiate the Unit Under Test (UUT)
  generate
    for (i = 0; i < 16; i = i + 1) begin : g_uuts
      trie8 #(
          .VC_ADDR_WIDTH(tb_VC_ADDR_WIDTH[i]),
          .VC_NEXT_ADDR_WIDTH(tb_VC_ADDR_WIDTH[i+1]),
          .VC_BIN_SIZE(tb_VC_BIN_SIZE[i]),
          .BEGIN_LEVEL(i * 8 + 1)
      ) uut (
          .clk(clk),
          .rst_p(rst_p),

          .frame_beat_i(frame_beat_i[i]),
          .frame_beat_o(frame_beat_o[i]),
          .in_valid(in_valid[i]),
          .out_ready(out_ready[i]),
          .in_ready(in_ready[i]),
          .out_valid(out_valid[i]),

          .vc_node_i(vc_node_i[i]),
          .vc_addr_o(vc_addr_o[i]),
          .vc_init_addr_i(vc_init_addr_i[i]),
          .vc_init_addr_o(vc_init_addr_o[i]),
          .vc_max_match_i(vc_max_match_i[i]),
          .vc_max_match_o(vc_max_match_o[i]),
          .vc_remaining_prefix_i(vc_remaining_prefix_i[i]),
          .vc_remaining_prefix_o(vc_remaining_prefix_o[i]),
          .vc_next_hop_offset_i(vc_next_hop_offset_i[i]),
          .vc_next_hop_offset_o(vc_next_hop_offset_o[i]),

          .bt_node_i(bt_node_i[i]),
          .bt_addr_o(bt_addr_o[i]),
          .bt_init_addr_i(bt_init_addr_i[i]),
          .bt_init_addr_o(bt_init_addr_o[i]),
          .bt_max_match_i(bt_max_match_i[i]),
          .bt_max_match_o(bt_max_match_o[i]),
          .bt_remaining_prefix_i(bt_remaining_prefix_i[i]),
          .bt_remaining_prefix_o(bt_remaining_prefix_o[i]),
          .bt_next_hop_offset_i(bt_next_hop_offset_i[i]),
          .bt_next_hop_offset_o(bt_next_hop_offset_o[i])
      );
    end
  endgenerate

  generate
    for (i = 0; i < 16; i = i + 1) begin : g_brams
      blk_mem_bt bram_i (
          .clka (clk),        // input wire clka
          .ena  (1'b1),   // input wire ena
          .wea  (1'b0),       // input wire [0 : 0] wea
          .addra(bt_addr_o[i]),  // input wire [12 : 0] addra
          .dina (0),          // input wire [35 : 0] dina
          .douta(bt_node_i[i]),  // wire [35 : 0] douta
          .clkb (clk),        // input wire clkb
          .enb  (1'b1),       // input wire enb
          .web  (web[i]),     // input wire [0 : 0] web
          .addrb(addrb[i]),   // input wire [12 : 0] addrb
          .dinb (dinb[i]),    // input wire [35 : 0] dinb
          .doutb(doutb[i])    // wire [35 : 0] doutb
      );
    end
  endgenerate

  frame_beat tb_frame_beat;
  // ===========================
  // Match
  // ===========================
  always @(posedge clk) begin
    if (rst_p) begin
      error <= 0;
    end else begin
      if (out_valid[15]) begin
        // TODO: Match the answer
        error <= (frame_beat_o[15] != tb_frame_beat) ? 1 : 0;
      end
    end
  end


  // ===========================
  // Testbench Logic
  // ===========================

  // Always block
  always #5 clk = ~clk;

  integer file;
  string line;
  int index = 0;
  logic [31:0] input_hex;
  logic [15:0] ipv6_16bit = 0;
  logic [3:0] char_hex = 0;
  int hex_count = 0;
  int ipv6_16bit_count = 0;
  // Initial block
  initial begin
    // TODO: Reset the signals
    frame_beat_i[0] = 0;
    in_valid[0] = 0;
    #100;
    rst_p = 1;
    #1000;
    rst_p = 0;
    // TODO: Load the binary trie from a file into brams
    for (int bram_num = 0; bram_num < 16; bram_num++) begin
        file = $fopen($sformatf("D:/web-2024/joint-lab-g5/firmware/trie/bram_%02d.txt", bram_num), "r");
        if (file == 0) begin
            $display($sformatf("Failed to open file %02d", bram_num));
            $finish;
        end
        while (!$feof(file) && index < 8192) begin
        $fgets(line, file);
            $sscanf(line, "%h", input_hex);
            dinb[bram_num][31:0] = input_hex;
            addrb[bram_num] = index;
            #10;
            web[bram_num] = 1;
            #10;
            web[bram_num] = 0;
            index++;
        end
    end
    $fclose(file);
    // TODO: Test the binary trie
    file = $fopen("D:/web-2024/joint-lab-g5/firmware/trie/fib_shuffled_0", "r");
    for (int i = 0; i < 255; i++) begin
        // TODO: Input
        #200
        tb_frame_beat.keep = ~0;
        tb_frame_beat.is_first = 1;
        tb_frame_beat.last = 1;
        tb_frame_beat.valid = 1;
        frame_beat_i[0] = tb_frame_beat;
        in_valid[0] = 1;

        // prefix example:
        // for ip6 address fe80::1
        // prefix should be 1000 .... 0000 0001 0111 1111
        pipeline_prefix = 0;
        hex_count = 0;
        ipv6_16bit_count = 0;
        $fgets(line, file);
        $sscanf(line, "%s", line);
        for (int j = 0; j < line.len(); j++) begin
            if (line[j] != ":") begin
                $sscanf(line[j], "%h", char_hex);
                char_hex[3:0] = {char_hex[0], char_hex[1], char_hex[2], char_hex[3]};
                ipv6_16bit += {12'd0, char_hex[3:0]} << (hex_count*4);
                hex_count += 1;
            end else begin
                for (int t = hex_count; t < 4; t++) begin
                    ipv6_16bit = ipv6_16bit << 4;
                end
                pipeline_prefix += {112'b0, ipv6_16bit} << (ipv6_16bit_count * 16);
                ipv6_16bit_count += 1;
                ipv6_16bit = 0;
                hex_count = 0;
            end
        end
        // pipeline_prefix = {80'h0, 48'h015b_ef64_4054};
        #200
        in_valid[0] = 0;
    end

    #10000;
    $finish;
  end
endmodule
// int main()
// {
//     init_bram();
//     FILE *file = fopen("fib_shuffled_0", "r");
//     char trash[50];
//     char ipv6_addr[50];
//     for(int i=0;i<255;i++){
//         struct RouteTableEntry entry;
//         entry.prefix[0] = 0x00000000;
//         entry.prefix[1] = 0x00000000;
//         entry.prefix[2] = 0x00000000;
//         entry.prefix[3] = 0x00000000;
//         fscanf_s(file, "%s %u %s %u\n", &ipv6_addr, sizeof(ipv6_addr),
//                         &(entry.prefix_length),
//                         &trash, sizeof(trash),
//                         &(entry.port));
//         char ch = '0';
//         int j = 0;
//         int pref = 0;
//         unsigned int a_1bit = 0;
//         unsigned int a_4bit = 0;
//         int high_4bit = 0;
//         unsigned int bitnum = 0;
//         while(1 == 1){
//             ch = ipv6_addr[j];
//             j++;
//             if(ch==':'){
//                 while(bitnum<4){
//                     a_4bit = a_4bit<<4;
//                     bitnum++;
//                 }
//                 bitnum=0;
//                 if(high_4bit==1){
//                     entry.prefix[pref] += a_4bit<<16;
//                     high_4bit=0;
//                     pref++;
//                 }
//                 else{
//                     entry.prefix[pref] += a_4bit;
//                     high_4bit=1;
//                 }
//                 a_4bit=0;
//                 if(ipv6_addr[j]==':') break;
//                 else continue;
//             }
//             else{
//                 if(ch<='9'){
//                     a_1bit = ch - '0';
//                 }
//                 else{
//                     a_1bit = ch - 'a' + 10;
//                 }
//                 unsigned int a_rev=0x0000;
//                 int ib=4;
//                 while(ib--){
//                     a_rev=a_rev+((a_1bit&0x0001)<<ib);
//                     a_1bit=a_1bit>>1;
//                 }
//                 a_4bit += a_rev<<bitnum*4;
//                 bitnum++;
//             }
//         }
//         // entry.prefix_length = 4;
//         entry.next_hop = 31;
//         int code = insert(entry.prefix, entry.prefix_length, entry.next_hop);
//         if (code != 0){
//             printf("Error on inserting route %d\n", i);
//             break;
//         }
//     }