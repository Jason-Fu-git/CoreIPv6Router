`timescale 1ns / 1ps
/**
 * Implementation of Neighbor Cache using CAM + BRAM, supporting the following operations:
 *
 * (1) Read Mode
 * Query MAC address from IPv6 address.
 * Input port `rea_p` should be positive.
 * Output port `r_MAC_addr` is the MAC address, if the key exists.
 * Output port `r_port_id` is the port id, if the key exists.
 * Output port `exists` is the flag indicating whether the key exists.
 *
 * (2) Write Mode
 * Insert / update / replace {IPv6 address, MAC address} pair.
 * Input port `wea_p` should be positive.
 * Input port `IPv6_addr` is the key.
 * Input port `w_MAC_addr` is the Mac address to save.
 * Input port `w_port_id` is the port id to save.
 *
 * (3) Update Mode
 * Reset the reachability timer of the entry.
 * Input port `uea_p` should be positive.
 * Input port `IPv6_addr` is the key.
 *
 * @author Jason Fu
 * @note
 *   - The reachability timer is implemented as a 32-bit counter.
 *     When the counter reaches the limit, the entry is invalidated.
 *     The limit can be set by the parameter `REACHABLE_LIMIT`,
 *     whose default value is 32'hFFFFFFF0 (approx 34s for 125MHz clock).
 *   - Only one of `uea_p`, `wea_p`, `rea_p` can be positive at a time, and should be positive until ready=1
 *   - DO NOT CHANGE ANY SIGNAL WHEN READY=0
 *   - Read operation is implemented as combinational logic, can complete within one cycle
 *
*/
module neighbor_cache #(
    parameter NUM_ENTRIES      = 16,
    parameter ENTRY_ADDR_WIDTH = 4,
    parameter REACHABLE_LIMIT  = 32'hFFFFFFF0,  // approx 34s for 125MHz clock
    // when the probe timer reaches this value, the external module should probe the IPv6 address
    parameter PROBE_LIMIT      = 32'hDFFFFFFF   // approx 30s for 125MHz clock
    // parameter PROBE_LIMIT      = 32'h1e848      // 1ms for debug
) (
    input wire clk,
    input wire rst_p,

    input  wire [127:0] IPv6_addr,   // Key : IPv6 address
    input  wire [ 47:0] w_MAC_addr,  // Value : MAC address (write)
    output reg  [ 47:0] r_MAC_addr,  // Value : MAC address (read)
    input  wire [  1:0] w_port_id,   // Value : port id (write)
    output reg  [  1:0] r_port_id,   // Value : port id (read)

    input wire uea_p,  // update enable, should be positive when notifying that the entry is reachable
    input wire wea_p,  // write enable, should be positive when writing mac address
    input wire rea_p,  // read enable, should be positive when reading

    output reg exists,  // FLAG : whether the key exists
    output reg ready,   // FLAG : whether the module is ready for next operation

    output reg nud_probe,  // FLAG : whether the external module should probe the IPv6 address
    output reg [127:0] probe_IPv6_addr,  // Key : IPv6 address to probe
    output reg [1:0] probe_port_id  // Value : port id to probe
);

  // ============================= NC entry ====================================
  typedef struct packed {
    reg valid;
    reg [1:0] port_id;
    reg [127:0] IPv6_addr;
    reg [47:0] MAC_addr;
    reg [31:0] reachable_timer;
  } neighbor_cache_entry_t;

  neighbor_cache_entry_t neighbor_cache_entries[NUM_ENTRIES];
  // ===========================================================================

  // ================================= write pulse ==============================
  reg prev_wea_p;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      prev_wea_p <= 0;
    end else begin
      if (prev_wea_p != wea_p) begin
        prev_wea_p <= wea_p;
      end
    end
  end
  // ===========================================================================

  // ============================= update pulse ================================
  reg prev_uea_p;

  always_ff @(posedge clk) begin
    if (rst_p) begin
      prev_uea_p <= 0;
    end else begin
      if (prev_uea_p != uea_p) begin
        prev_uea_p <= uea_p;
      end
    end
  end
  // ===========================================================================


  // ============================= state transfer ================================
  typedef enum reg [1:0] {
    ST_IDLE,
    ST_WRITE,
    ST_UPDATE,
    ST_SAVE
  } neighbor_cache_state_t;
  neighbor_cache_state_t state;

  always_ff @(posedge clk) begin : StateTransfer
    if (rst_p) begin
      state <= ST_IDLE;
    end else begin
      case (state)
        ST_IDLE: begin
          if (uea_p && !prev_uea_p) begin
            state <= ST_UPDATE;
          end else if (wea_p && !prev_wea_p) begin
            state <= ST_WRITE;
          end
        end
        ST_WRITE: begin
          state <= ST_SAVE;
        end
        ST_UPDATE: begin
          state <= ST_IDLE;
        end
        ST_SAVE: begin
          state <= ST_IDLE;
        end
        default: state <= ST_IDLE;
      endcase
    end
  end

  assign ready = (state == ST_IDLE);
  // ==========================================================================


  reg [ENTRY_ADDR_WIDTH-1:0] update_addr;  // write address, used for updating
  reg [ENTRY_ADDR_WIDTH-1:0] insert_addr;  // write address, used for inserting

  // next replace address. If the table is full and query fails, this is the address to replace.
  reg [ENTRY_ADDR_WIDTH-1:0] next_replace_addr;

  // insertability flag
  reg insertable;

  // updatablitity flag
  reg updatable;

  always_ff @(posedge clk) begin
    if (rst_p || (!uea_p && !wea_p && !rea_p)) begin
      exists <= 0;
    end else begin
      if (updatable) begin
        exists <= 1;
      end
    end
  end


  // =================== CAM entry query, higher address first =============
  always_comb begin : CAM

    updatable   = 0;

    update_addr = 0;
    r_MAC_addr  = 0;
    r_port_id   = 0;

    if (wea_p) begin  // write
      for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
        if(neighbor_cache_entries[i].valid && neighbor_cache_entries[i].IPv6_addr == IPv6_addr) begin
          // update MAC address
          updatable   = 1;
          update_addr = i;
        end
      end
    end else if (rea_p) begin  // read mode
      for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
        if(neighbor_cache_entries[i].valid && neighbor_cache_entries[i].IPv6_addr == IPv6_addr) begin
          // read MAC address
          updatable  = 1;
          r_MAC_addr = neighbor_cache_entries[i].MAC_addr;
          r_port_id  = neighbor_cache_entries[i].port_id;
        end
      end
    end
  end
  // ===========================================================================


  // ============== search for CAM empty entry, lower address first ============
  always_comb begin : empty_entry
    insertable  = 0;
    insert_addr = 0;

    if (wea_p) begin
      for (int i = NUM_ENTRIES - 1; i >= 0; i = i - 1) begin
        if (!neighbor_cache_entries[i].valid) begin
          insertable  = 1;
          insert_addr = i;
        end
      end
    end
  end
  // ===========================================================================


  // ======================== write controller =================================
  always_ff @(posedge clk) begin
    if (rst_p) begin
      // reset next replace address
      next_replace_addr <= 0;
      for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
        neighbor_cache_entries[i].MAC_addr  <= 0;
        neighbor_cache_entries[i].IPv6_addr <= 0;
        neighbor_cache_entries[i].port_id   <= 0;
      end
    end else begin
      if (state == ST_SAVE) begin
        if (updatable) begin
          // update MAC address and port id
          neighbor_cache_entries[update_addr].MAC_addr <= w_MAC_addr;
          neighbor_cache_entries[update_addr].port_id  <= w_port_id;
        end else if (insertable) begin
          // insert new entry
          neighbor_cache_entries[insert_addr].IPv6_addr <= IPv6_addr;
          neighbor_cache_entries[insert_addr].MAC_addr  <= w_MAC_addr;
          neighbor_cache_entries[insert_addr].port_id   <= w_port_id;
        end else begin
          // replace entry
          neighbor_cache_entries[next_replace_addr].IPv6_addr <= IPv6_addr;
          neighbor_cache_entries[next_replace_addr].MAC_addr <= w_MAC_addr;
          neighbor_cache_entries[next_replace_addr].port_id <= w_port_id;
          next_replace_addr <= next_replace_addr + 1;
          if (next_replace_addr >= NUM_ENTRIES - 1) begin
            next_replace_addr <= 0;
          end
        end
      end
    end
  end
  // ===========================================================================


  // ================ reachability timer / validity controller =================
  always_ff @(posedge clk) begin : Timer
    if (rst_p) begin
      // reset all entries
      for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
        neighbor_cache_entries[i].reachable_timer <= 0;
        neighbor_cache_entries[i].valid <= 0;
      end
    end else begin
      // iterate through all entries, if valid, increment timer
      for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
        if (state == ST_UPDATE && neighbor_cache_entries[i].IPv6_addr == IPv6_addr) begin
          // reset timer
          neighbor_cache_entries[i].reachable_timer <= 0;
        end else if (state == ST_SAVE) begin
          if (updatable) begin
            if (i == update_addr) begin
              // update entry
              neighbor_cache_entries[i].valid <= 1;
              neighbor_cache_entries[i].reachable_timer <= 0;
            end else begin
              if (neighbor_cache_entries[i].valid) begin
                // increment timer
                if (neighbor_cache_entries[i].reachable_timer >= REACHABLE_LIMIT) begin
                  neighbor_cache_entries[i].reachable_timer <= 0;
                  neighbor_cache_entries[i].valid <= 0;
                end else begin
                  neighbor_cache_entries[i].reachable_timer
                 <= neighbor_cache_entries[i].reachable_timer + 1;
                end
              end
            end
          end else if (insertable) begin
            if (i == insert_addr) begin
              // insert entry
              neighbor_cache_entries[i].valid <= 1;
              neighbor_cache_entries[i].reachable_timer <= 0;
            end else begin
              if (neighbor_cache_entries[i].valid) begin
                // increment timer
                if (neighbor_cache_entries[i].reachable_timer >= REACHABLE_LIMIT) begin
                  neighbor_cache_entries[i].reachable_timer <= 0;
                  neighbor_cache_entries[i].valid <= 0;
                end else begin
                  neighbor_cache_entries[i].reachable_timer
                 <= neighbor_cache_entries[i].reachable_timer + 1;
                end
              end
            end
          end else begin
            if ((i == next_replace_addr)) begin
              // replace entry
              neighbor_cache_entries[i].valid <= 1;
              neighbor_cache_entries[i].reachable_timer <= 0;
            end else begin
              if (neighbor_cache_entries[i].valid) begin
                // increment timer
                if (neighbor_cache_entries[i].reachable_timer >= REACHABLE_LIMIT) begin
                  neighbor_cache_entries[i].reachable_timer <= 0;
                  neighbor_cache_entries[i].valid <= 0;
                end else begin
                  neighbor_cache_entries[i].reachable_timer
                 <= neighbor_cache_entries[i].reachable_timer + 1;
                end
              end
            end
          end
        end else begin
          if (neighbor_cache_entries[i].valid) begin
            // increment timer
            if (neighbor_cache_entries[i].reachable_timer >= REACHABLE_LIMIT) begin
              neighbor_cache_entries[i].reachable_timer <= 0;
              neighbor_cache_entries[i].valid <= 0;
            end else begin
              neighbor_cache_entries[i].reachable_timer
                <= neighbor_cache_entries[i].reachable_timer + 1;
            end
          end
        end
      end
    end
  end
  // ===========================================================================


  // ========================== probe controller  ==============================
  always_comb begin : ProbeController
    nud_probe = 0;
    probe_IPv6_addr = 0;
    probe_port_id = 0;

    for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
      if (neighbor_cache_entries[i].valid && neighbor_cache_entries[i].reachable_timer == PROBE_LIMIT) begin
        nud_probe = 1;
        probe_IPv6_addr = neighbor_cache_entries[i].IPv6_addr;
        probe_port_id = neighbor_cache_entries[i].port_id;
      end
    end
  end
  // ===========================================================================




endmodule
