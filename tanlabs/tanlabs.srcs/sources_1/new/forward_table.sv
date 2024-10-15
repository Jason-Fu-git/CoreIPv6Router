
// {0, valid, prefix_len, next_hop_addr, prefix}
module forward_table #(
    BASE_ADDR  = 2'h0,
    MAX_ADDR   = 2'h3,
    ADDR_WIDTH = 2
) (
    input wire clk,
    input wire rst_p,

    input wire ea_p,  // Only Read Mode
    input wire [127:0] ip6_addr,
    input wire [7:0] prefix_len,

    output reg [127:0] next_hop_addr,
    output reg ready,

    // external memory
    output wire [ADDR_WIDTH-1:0] mem_addr,
    output wire mem_rea_p,
    input reg [319:0] mem_data,
    input reg mem_ack_p
);
  // Trigger
  reg prev_ea_p;
  reg trigger;
  assign trigger = ea_p && !prev_ea_p;
  always_ff @(posedge clk) begin
    if (rst_p) begin
      prev_ea_p <= 0;
    end else begin
      prev_ea_p <= ea_p;
    end
  end


  // Match
  reg hit;
  reg [ADDR_WIDTH-1:0] _mem_addr_comb;
  reg [ADDR_WIDTH-1:0] _mem_addr_reg;
  reg [127:0] _prefix;
  reg [127:0] _next_hop_addr;
  reg [7:0] _prefix_len;
  reg _valid;

  always_comb begin : Match
    if (_valid) begin
      _mem_addr_comb = _mem_addr_reg + 1;
    end else begin
      _mem_addr_comb = _mem_addr_reg + 1;
    end
  end


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

      next_hop_addr <= 0;
      ready <= 0;

      mem_addr <= 0;
      mem_rea_p <= 0;

      _valid <= 0;
    end else begin
      case (state)
        ST_IDLE: begin
          if (trigger) begin
            state <= ST_READ_MEM;

            mem_addr <= _mem_addr;
            mem_rea_p <= 1;
            ready <= 0;
          end else begin
            state <= ST_IDLE;

            mem_rea_p <= 0;
            ready <= 1;
          end
        end
        ST_READ_MEM: begin
          if (mem_ack_p) begin
            state <= ST_MATCH;

            {_valid, _prefix_len, _next_hop_addr, _prefix} <= mem_data;
          end
        end
        ST_MATCH: begin
          if (hit) begin
            state <= ST_IDLE;
          end else begin
            state <= ST_READ_MEM;
          end
        end
        default: begin
          state <= ST_IDLE;
        end
      endcase
    end
  end

endmodule


