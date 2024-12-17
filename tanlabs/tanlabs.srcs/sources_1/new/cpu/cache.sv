`timescale 1ns / 1ps

localparam BYTE_WIDTH = 8;

// SRAM共4MB，地址宽度为20，CPU访问宽度为22
//
// CPU address input:
// | TAG | GROUP | BYTE |
// |21~~6|5~~~~~2|1~~~~0|
//
// SRAM address output:
// | TAG | GROUP |
// |19~~4|3~~~~~0|
//
// CACHE LINE STRUCTURE:
// |   TAG   |   DATA  | LRU COUNTER | VALID |
// | 16 bits | 32 bits | group width | 1 bit |

// 1. CPU给定地址后，
// 2. 根据GROUP确定在哪一组，
// 3. 查找组内是否命中


module cache #(
    parameter BLOCK_WIDTH,  // 字节宽，2
    parameter BLOCK_SIZE,   // 块大小，4
    parameter TAG_WIDTH,    // 地址前缀长度，17
    parameter GROUP_NUM,    // 组数，16
    parameter GROUP_WIDTH,  // 组数宽度，4
    parameter GROUP_SIZE    // 每组路数，任意
) (
    input wire clk,
    input wire rst_p,

    input wire [TAG_WIDTH+GROUP_WIDTH+BLOCK_WIDTH-1:0] adr_ctl_i,
    input wire stb_ctl_i,
    input wire [BLOCK_SIZE-1:0] sel_ctl_i,
    input wire we_p_ctl_i,
    output reg ack_ctl_o,
    input wire [BLOCK_SIZE*BYTE_WIDTH-1:0] dat_ctl_i,
    output reg [BLOCK_SIZE*BYTE_WIDTH-1:0] dat_ctl_o,

    input wire ack_sram_i,
    output reg stb_sram_o,
    output reg [TAG_WIDTH+GROUP_WIDTH+BLOCK_WIDTH-1:0] adr_sram_o,
    output reg [BLOCK_SIZE-1:0] sel_sram_o,
    output reg we_p_sram_o,
    input wire [BLOCK_SIZE*BYTE_WIDTH-1:0] dat_sram_i,
    output reg [BLOCK_SIZE*BYTE_WIDTH-1:0] dat_sram_o,

    input wire fence  // If `fence` when posedge stb_ctl_i, write back and clear all
);

  reg ack_ctl_o_reg;

  typedef struct packed {
    logic [TAG_WIDTH-1:0]             tag;
    logic [BLOCK_SIZE*BYTE_WIDTH-1:0] data;
    logic [GROUP_WIDTH-1:0]           lru;
    logic                             valid;
    logic                             dirty;
  } cache_line_t;

  typedef struct packed {
    logic [TAG_WIDTH-1:0]   tag;
    logic [GROUP_WIDTH-1:0] group;
    logic [BLOCK_WIDTH-1:0] bytes;
  } address_t;

  cache_line_t [GROUP_NUM-1:0][GROUP_SIZE-1:0] cache_file;

  address_t address_in;
  assign address_in = adr_ctl_i;
  logic [BLOCK_WIDTH-1:0] in_byte;
  assign in_byte = address_in.bytes;
  logic [GROUP_WIDTH-1:0] in_group;
  assign in_group = address_in.group;
  logic [TAG_WIDTH-1:0] in_tag;
  assign in_tag = address_in.tag;

  logic                             cache_hit;
  logic [   $clog2(GROUP_SIZE)-1:0] hit_index;
  logic [BLOCK_SIZE*BYTE_WIDTH-1:0] hit_data;

  always_comb begin
    cache_line_t [GROUP_WIDTH-1:0] line = cache_file[in_group];
    cache_hit = 0;
    hit_data  = 0;
    hit_index = 0;
    for (int i = 0; i < GROUP_SIZE; i = i + 1) begin
      if (line[i].valid && (line[i].tag == in_tag)) begin
        cache_hit = 1;
        hit_index = i;
        hit_data  = line[i].data;
      end
    end
  end

  logic acquiring;  // True if accessing RAM, namely not free
  logic writing;  // True if going to write back
  logic [TAG_WIDTH+GROUP_WIDTH+BLOCK_WIDTH-1:0] adr_ctl_i_reg;
  logic [BLOCK_SIZE-1:0] sel_ctl_i_reg;
  logic we_p_ctl_i_reg;
  logic [BLOCK_SIZE*BYTE_WIDTH-1:0] dat_ctl_i_reg;
  logic [GROUP_WIDTH-1:0] in_group_reg;

  logic cache_line_full;
  logic [$clog2(GROUP_SIZE)-1:0] valid_index;
  address_t address_in_reg;
  assign address_in_reg = adr_ctl_i_reg;
  logic [$clog2(GROUP_SIZE)-1:0] lru_index;
  logic [       GROUP_WIDTH-1:0] lru_max;

  always_comb begin
    cache_line_full = 1;
    valid_index     = 0;
    lru_index       = 0;
    lru_max         = 0;
    for (int i = 0; i < GROUP_SIZE; i = i + 1) begin
      if (!cache_file[in_group_reg][i].valid) begin
        cache_line_full = 0;
        valid_index     = i;
      end else begin
        if (cache_file[in_group_reg][i].lru > lru_max) begin
          lru_max   = cache_file[in_group_reg][i].lru;
          lru_index = i;
        end
      end
    end
  end

  logic                          fencing;
  logic [       GROUP_WIDTH-1:0] fence_group;
  logic [$clog2(GROUP_SIZE)-1:0] fence_line;

  typedef enum logic [3:0] {
    IDLE,
    FENCE,
    WAIT,
    DONE
  } fence_state_t;

  fence_state_t fence_state, fence_next_state;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      fence_state <= IDLE;
    end else begin
      fence_state <= fence_next_state;
    end
  end

  always_comb begin
    case (fence_state)
      IDLE: fence_next_state = (stb_ctl_i && fence && !ack_ctl_o_reg) ? FENCE : IDLE;
      FENCE:
      fence_next_state = ((fence_group == {GROUP_WIDTH{1'b1}}) &&
                          (fence_line == {$clog2(GROUP_SIZE) {1'b1}})) ? WAIT : FENCE;
      WAIT: fence_next_state = (fencing ? (ack_sram_i ? DONE : WAIT) : DONE);
      DONE: fence_next_state = IDLE;
      default: fence_next_state = IDLE;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst_p) begin
      ack_ctl_o_reg   <= 0;
      stb_sram_o  <= 0;
      acquiring   <= 0;
      writing     <= 0;
      cache_file  <= '0;
      fence_group <= 0;
      fence_line  <= 0;
      fencing     <= 0;
    end else begin
      if ((fence_state == FENCE) && !fencing) begin
        if ((cache_file[fence_group][fence_line].valid) && (cache_file[fence_group][fence_line].dirty)) begin
          fencing <= 1;
          stb_sram_o <= 1;
          dat_sram_o <= cache_file[fence_group][fence_line].data;
          adr_sram_o <= {cache_file[fence_group][fence_line].tag, fence_group, {BLOCK_WIDTH{1'b0}}};
          we_p_sram_o <= 1;
        end
        cache_file[fence_group][fence_line] <= '0;
        if (fence_line == {$clog2(GROUP_SIZE) {1'b1}}) begin
          fence_line <= 0;
          if (fence_group == {GROUP_WIDTH{1'b1}}) begin
            fence_group <= 0;
          end else begin
            fence_group <= fence_group + 1;
          end
        end else begin
          fence_line <= fence_line + 1;
        end
      end else if (((fence_state == FENCE) || (fence_state == WAIT)) && fencing && ack_sram_i) begin
        fencing    <= 0;
        stb_sram_o <= 0;
      end else if (fence_state == DONE) begin
        ack_ctl_o_reg <= 1;
      end else if (stb_ctl_i && !acquiring && !writing && !fence) begin  // when free
        if (cache_hit) begin
          ack_ctl_o_reg <= 1;
          if (!we_p_ctl_i) begin  // Read cache hit
            dat_ctl_o <= hit_data;
            cache_file[in_group][hit_index].lru <= 0;
            for (int i = 0; i < GROUP_SIZE; i = i + 1) begin
              if (i != hit_index) begin
                if ((cache_file[in_group][i].valid) && (cache_file[in_group][i].lru != ~'0)) begin
                  cache_file[in_group][i].lru <= cache_file[in_group][i].lru + 1;
                end
              end
            end
          end else begin  // Write cache hit, write-back policy
            cache_file[in_group][hit_index].dirty <= 1;
            for (int i = 0; i < BLOCK_SIZE; i = i + 1) begin
              if (sel_ctl_i[i]) begin
                cache_file[in_group][hit_index].data[i*BYTE_WIDTH+:BYTE_WIDTH] <= dat_ctl_i[i*BYTE_WIDTH+:BYTE_WIDTH];
              end
            end
            cache_file[in_group][hit_index].lru <= 0;
            for (int i = 0; i < GROUP_SIZE; i = i + 1) begin
              if (i != hit_index) begin
                if ((cache_file[in_group][i].valid) && (cache_file[in_group][i].lru != ~'0)) begin
                  cache_file[in_group][i].lru <= cache_file[in_group][i].lru + 1;
                end
              end
            end
          end
        end else begin  // cache miss
          ack_ctl_o_reg      <= 0;
          acquiring      <= 1;
          stb_sram_o     <= 1;
          adr_ctl_i_reg  <= adr_ctl_i;
          sel_ctl_i_reg  <= sel_ctl_i;
          we_p_ctl_i_reg <= we_p_ctl_i;
          dat_ctl_i_reg  <= dat_ctl_i;
          in_group_reg   <= in_group;
          we_p_sram_o    <= 0;
          //   adr_sram_o     <= adr_ctl_i[TAG_WIDTH+GROUP_WIDTH+BLOCK_WIDTH-1:BLOCK_WIDTH];
          adr_sram_o     <= adr_ctl_i;
          sel_sram_o     <= ~'0;
        end
      end else if (acquiring && ack_sram_i) begin
        acquiring  <= 0;
        stb_sram_o <= 0;
        if (cache_line_full) begin
          if (cache_file[in_group_reg][lru_index].dirty) begin
            adr_sram_o <= {
              cache_file[in_group_reg][lru_index].tag, in_group_reg, {BLOCK_WIDTH{1'b0}}
            };
            dat_sram_o <= cache_file[in_group_reg][lru_index].data;
            we_p_sram_o <= 1;
            writing <= 1;
          end
          cache_file[in_group_reg][lru_index].data  <= dat_sram_i;
          cache_file[in_group_reg][lru_index].valid <= 1;
          cache_file[in_group_reg][lru_index].lru   <= 0;
          cache_file[in_group_reg][lru_index].dirty <= we_p_ctl_i_reg;
          cache_file[in_group_reg][lru_index].tag   <= address_in_reg.tag;
          if (we_p_ctl_i_reg) begin
            for (int i = 0; i < BLOCK_SIZE; i = i + 1) begin
              if (sel_ctl_i[i]) begin
                cache_file[in_group][lru_index].data[i*BYTE_WIDTH+:BYTE_WIDTH] <= dat_ctl_i_reg[i*BYTE_WIDTH+:BYTE_WIDTH];
              end
            end
          end
          cache_file[in_group_reg][lru_index].lru <= 0;
          for (int i = 0; i < GROUP_SIZE; i = i + 1) begin
            if (i != lru_index) begin
              if ((cache_file[in_group_reg][i].valid) && (cache_file[in_group_reg][i].lru != ~'0)) begin
                cache_file[in_group_reg][i].lru <= cache_file[in_group_reg][i].lru + 1;
              end
            end
          end
        end else begin
          ack_ctl_o_reg <= 1;
          if (!we_p_ctl_i) begin
            dat_ctl_o <= dat_sram_i;
          end
          cache_file[in_group_reg][valid_index].data  <= dat_sram_i;
          cache_file[in_group_reg][valid_index].valid <= 1;
          cache_file[in_group_reg][valid_index].lru   <= 0;
          cache_file[in_group_reg][valid_index].dirty <= we_p_ctl_i_reg;
          cache_file[in_group_reg][valid_index].tag   <= address_in_reg.tag;
          if (we_p_ctl_i_reg) begin
            for (int i = 0; i < BLOCK_SIZE; i = i + 1) begin
              if (sel_ctl_i[i]) begin
                cache_file[in_group][valid_index].data[i*BYTE_WIDTH+:BYTE_WIDTH] <= dat_ctl_i_reg[i*BYTE_WIDTH+:BYTE_WIDTH];
              end
            end
          end
          cache_file[in_group_reg][valid_index].lru <= 0;
          for (int i = 0; i < GROUP_SIZE; i = i + 1) begin
            if (i != valid_index) begin
              if ((cache_file[in_group_reg][i].valid) && (cache_file[in_group_reg][i].lru != ~'0)) begin
                cache_file[in_group_reg][i].lru <= cache_file[in_group_reg][i].lru + 1;
              end
            end
          end
        end
      end else if (writing) begin
        if (!stb_sram_o) begin
          stb_sram_o <= 1;
        end else begin
          if (ack_sram_i) begin
            stb_sram_o <= 0;
            writing    <= 0;
            ack_ctl_o_reg  <= 1;
            if (!we_p_ctl_i) begin
              dat_ctl_o <= hit_data;
            end
          end
        end
      end else begin
        ack_ctl_o_reg <= 0;
      end
    end
  end

  assign ack_ctl_o = ack_ctl_o_reg && (stb_ctl_i || fence);

endmodule : cache
