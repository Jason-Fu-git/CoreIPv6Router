`timescale 1ns / 1ps
`include "frame_datapath.vh"

/**
*  @brief  Forward Table
*  @note
*   - FIXME: A brute force search.
*
*   Entry Format:
*   - Forward Table entry format: {0s, valid, prefix_len, next_hop_addr, prefix}
*   - The table is stored in an external memory.
*   - The external memory is controlled by the bram_controller.
*
*   Input Format:
*   - The prefix, ip6_addr and next_hop_addr are (should be) in small endian.
*     e.g. 000000000000000000000000000080FF
*   - The prefix_len is the number of bits in the prefix. e.g. 16
*
*   Address Range:
*   - The valid address range is from [BASE_ADDR, MAX_ADDR].
*
*   Enable Signal:
*   - in_beat.valid is the trigger signal for reading the table.
*
*
*  @see bram_controller.sv, tb_forward_table.sv
*  @author Jason Fu
*
*/
module forward_table #(
    BASE_ADDR  = 2'h0,
    MAX_ADDR   = 2'h3,
    DATA_WIDTH = 320,
    ADDR_WIDTH = 5
) (
    input wire clk,
    input wire rst_p,

    input  fw_frame_beat_t in_beat,
    output fw_frame_beat_t out_beat,

    input  wire out_ready,  // External reg ready
    output reg  in_ready,   // Ready for next query

    // external memory
    input  wire [DATA_WIDTH-1:0] mem_data,
    input  wire                  mem_ack_p,
    output reg  [ADDR_WIDTH-1:0] mem_addr,
    output reg                   mem_rea_p

);


  // ================== Match ======================
  reg                  hit;
  reg [ADDR_WIDTH-1:0] next_mem_addr;

  // Data from memory
  reg [         127:0] prefix;
  reg [         127:0] next_hop_addr;
  reg [           7:0] prefix_len;
  reg                  mem_valid;

  // Mask for prefix
  reg [         127:0] prefix_mask;
  assign prefix_mask = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >> (128 - prefix_len);


  // FIXME: A brute force search
  reg [7:0] max_prefix_len;

  always_comb begin : Match
    next_mem_addr = mem_addr + 1;
    if (mem_valid) begin
      if ((out_beat.data.data.ip6.dst & prefix_mask) == (prefix & prefix_mask)) begin
        hit = 1;
      end else begin
        hit = 0;
      end
    end else begin
      hit = 0;
    end
  end
  // ===============================================


  // ===================== Controller ==============
  // State Machine
  typedef enum logic [1:0] {
    ST_IDLE,
    ST_READ_MEM,
    ST_MATCH
  } fwt_state_t;

  fwt_state_t fwt_state;

  // State Transfer
  always_ff @(posedge clk) begin : Controller
    if (rst_p) begin
      fwt_state      <= ST_IDLE;

      mem_rea_p      <= 0;
      mem_addr       <= 0;

      mem_valid      <= 0;
      prefix_len     <= 0;
      next_hop_addr  <= 0;
      prefix         <= 0;
      max_prefix_len <= 0;
    end else begin
      case (fwt_state)
        ST_IDLE: begin
          max_prefix_len <= 0;
          if (in_ready) begin
            if (in_beat.data.is_first && in_beat.valid && (in_beat.error == ERR_NONE)) begin
              // Start search
              fwt_state     <= ST_READ_MEM;
              // Memory controller
              mem_addr  <= BASE_ADDR;
              mem_rea_p <= 1;
            end else begin
              // Memory controller
              mem_addr  <= BASE_ADDR;
              mem_rea_p <= 0;
            end
          end else begin
            // Memory controller
            mem_addr  <= BASE_ADDR;
            mem_rea_p <= 0;
          end
        end
        ST_READ_MEM: begin
          if (mem_ack_p) begin
            // Read Memory
            fwt_state                                      <= ST_MATCH;
            {mem_valid, prefix_len, next_hop_addr, prefix} <= mem_data;
            mem_rea_p                                      <= 0;
          end
        end
        ST_MATCH: begin
          if (hit) begin
            // Update Max Prefix Length
            if (prefix_len > max_prefix_len) begin
              max_prefix_len <= prefix_len;
            end
          end
          // Check if it is the last entry
          if (mem_addr == MAX_ADDR) begin
            // End of Table
            fwt_state     <= ST_IDLE;
          end else begin
            // Next Entry
            fwt_state     <= ST_READ_MEM;

            mem_addr      <= next_mem_addr;
            mem_rea_p     <= 1;
          end
        end
        default: begin
          fwt_state       <= ST_IDLE;
        end
      endcase
    end
  end
  // ======================================================

  assign in_ready = (fwt_state == ST_IDLE) && (out_ready || (!out_beat.valid));


  // ======= Out beat construction ===========================
  always_ff @(posedge clk) begin : OutBeat
    if (rst_p) begin
      out_beat <= 0;
    end else begin
      if (in_ready) begin
        if (!in_beat.data.is_first) begin
          out_beat <= in_beat;
        end else if (in_beat.valid) begin
          out_beat.data <= in_beat.data;
          if (in_beat.error == ERR_NONE) begin
            out_beat.error <= ERR_FWT_MISS;
            // Insert a bubble
            out_beat.valid <= 0;
          end else begin
            // Valid input but has errors. Directly pass it.
            out_beat.error <= in_beat.error;
            out_beat.valid <= 1;
          end
        end
      end else begin
        if (fwt_state == ST_IDLE) begin
          out_beat.valid <= 0;
        end else if (fwt_state == ST_READ_MEM) begin
          out_beat.valid <= 0;
        end else if (fwt_state == ST_MATCH) begin
          if (hit) begin
            // Update Max Prefix Length
            if (prefix_len > max_prefix_len) begin
              out_beat.data.data.ip6.dst <= next_hop_addr;
              if (out_beat.error == ERR_FWT_MISS) begin
                // Clean the error signal
                out_beat.error <= ERR_NONE;
              end
            end
            // Check if it is the last entry
            if (mem_addr == MAX_ADDR) begin
              // Query done, send the result
              out_beat.valid <= 1;
            end
          end
        end
      end
    end
  end
  // ========================================================

endmodule


