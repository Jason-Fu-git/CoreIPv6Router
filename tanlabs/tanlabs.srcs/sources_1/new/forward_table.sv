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

    input wire            step,    // Only Read Mode
    input fw_frame_beat_t in_beat,

    output fw_frame_beat_t out_beat,
    input  reg             out_ready,  // External reg ready
    output reg             in_ready,   // Ready for next query
    output reg             exists,

    // external memory
    input  wire [DATA_WIDTH-1:0] mem_data,
    input  wire                  mem_ack_p,
    output reg  [ADDR_WIDTH-1:0] mem_addr,
    output reg                   mem_rea_p

);


  // ================== Match ======================
  reg hit;
  reg [ADDR_WIDTH-1:0] next_mem_addr;
  reg [ADDR_WIDTH-1:0] _mem_addr;

  // Data from memory
  reg [127:0] _prefix;
  reg [127:0] _next_hop_addr;
  reg [7:0] _prefix_len;
  reg _valid;

  // Mask for prefix
  reg [127:0] _prefix_mask;
  assign _prefix_mask = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >> (128 - _prefix_len);


  // === FIXME: A brute force search ===
  reg [7:0] _max_prefix_len;
  // ===================================

  assign mem_addr = _mem_addr;
  always_comb begin : Match
    next_mem_addr = _mem_addr + 1;

    if (_valid) begin
      if ((out_beat.data.data.ip6.dst & _prefix_mask) == (_prefix & _prefix_mask)) begin
        hit = 1;
      end else begin
        hit = 0;
      end
    end else begin
      hit = 0;
    end
  end
  // ===============================================


  // ===================== Controller =====================
  // State Machine
  typedef enum logic [1:0] {
    ST_IDLE,
    ST_READ_MEM,
    ST_MATCH
  } state_t;

  state_t state;

  // State Transfer
  always_ff @(posedge clk) begin
    if (rst_p) begin
      state <= ST_IDLE;

      out_beat <= 0;
      in_ready <= 1;
      exists <= 0;

      mem_rea_p <= 0;

      _mem_addr <= 0;
      _valid <= 0;
      _prefix_len <= 0;
      _next_hop_addr <= 0;
      _prefix <= 0;
      _max_prefix_len <= 0;
    end else begin
      case (state)
        ST_IDLE: begin
          exists          <= 0;
          _max_prefix_len <= 0;
          mem_rea_p       <= 0;

          if (in_ready) begin
            if (in_beat.valid) begin
              // Not ready for next query
              in_ready       <= 0;
              // Construct Output
              out_beat.data    <= in_beat.data;
              out_beat.index   <= in_beat.index;
              out_beat.stop    <= in_beat.stop;
              out_beat.waiting <= in_beat.waiting;
              if (in_beat.error == ERR_NONE) begin
                out_beat.error <= ERR_FWT_MISS;
                // Insert a bubble
                out_beat.valid <= 0;
                // Start search
                state          <= ST_READ_MEM;
                // Memory controller
                _mem_addr      <= BASE_ADDR;
                mem_rea_p      <= 1;
              end else begin
                out_beat.error <= in_beat.error;
                // Valid input but has errors. Directly pass it.
                out_beat.valid <= 1;
              end
            end else begin
              // Received a bubble, pass it.
              out_beat.valid <= 0;
            end
          end else begin
            // !in_ready
            if (out_ready) begin
              in_ready       <= 1;
              out_beat.valid <= 0; // This packet is expired. Insert a bubble.
            end
          end

        end
        ST_READ_MEM: begin
          if (mem_ack_p) begin
            // Read Memory
            state <= ST_MATCH;
            {_valid, _prefix_len, _next_hop_addr, _prefix} <= mem_data;
            mem_rea_p <= 0;
          end
        end
        ST_MATCH: begin
          if (hit) begin
            // Update Max Prefix Length
            if (_prefix_len > _max_prefix_len) begin
              _max_prefix_len            <= _prefix_len;
              out_beat.data.data.ip6.dst <= _next_hop_addr;
              exists                     <= 1;
              if (out_beat.error == ERR_FWT_MISS) begin
                // Clean the error signal
                out_beat.error <= ERR_NONE;
              end
            end
          end
          // Check if it is the last entry
          if (_mem_addr == MAX_ADDR) begin
            // End of Table
            state <= ST_IDLE;

            // Query done, send the result
            out_beat.valid <= 1;
            if (out_ready) begin
              in_ready <= 1;
            end
          end else begin
            // Next Entry
            state <= ST_READ_MEM;

            _mem_addr <= next_mem_addr;
            mem_rea_p <= 1;
          end
        end
        default: begin
          state <= ST_IDLE;
        end
      endcase
    end
  end
  // ======================================================

endmodule


