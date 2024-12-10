`timescale 1ns / 1ps
/**
 * Implementation of Neighbor Cache using CAM + BRAM, supporting the following operations:
 *
 * (1) Read Mode
 * Query MAC address from IPv6 address.
 * Input port  `r_IPv6_addr` is the key.
 * Output port `r_MAC_addr` is the MAC address, if the key exists.
 * Output port `r_port_id` is the port id, if the key exists.
 * Output port `exists` is the flag indicating whether the key exists.
 *
 * (2) Write Mode
 * Insert / update / replace {IPv6 address, MAC address} pair.
 * Input port `wea_p` should be positive.
 * Input port `w_IPv6_addr` is the key.
 * Input port `w_MAC_addr` is the Mac address to save.
 * Input port `w_port_id` is the port id to save.
 *
 *
 * @author Jason Fu
 * @note
 *   - The reachability timer is implemented as a 32-bit counter.
 *     When the counter reaches the limit, the entry is invalidated.
 *     The limit can be set by the parameter `REACHABLE_LIMIT`,
 *     whose default value is 32'hFFFFFFF0 (approx 34s for 125MHz clock).
 *   - DO NOT CHANGE ANY SIGNAL WHEN READY=0.
 *   - Read operation is implemented as combinational logic, can complete within one cycle
 *   - Write operation is implemented as sequential logic, can complete within one cycle
 *   - Every time when `wea_p` is 1, the module will trigger a write operation.
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

    // Read port 0
    input  wire [127:0] r_IPv6_addr_0,  // Key : IPv6 address
    output reg  [ 47:0] r_MAC_addr_0,   // Value : MAC address (read)
    output reg  [  1:0] r_port_id_0,    // Value : port id (read)
    output reg          r_exists_0,     // FLAG : whether the key exists

    // Read port 1
    input  wire [127:0] r_IPv6_addr_1,  // Key : IPv6 address
    output reg  [ 47:0] r_MAC_addr_1,   // Value : MAC address (read)
    output reg  [  1:0] r_port_id_1,    // Value : port id (read)
    output reg          r_exists_1,     // FLAG : whether the key exists

    // Write port
    input wire [127:0] w_IPv6_addr,  // Key : IPv6 address (write)
    input wire [ 47:0] w_MAC_addr,   // Value : MAC address (write)
    input wire [  1:0] w_port_id,    // Value : port id (write)

    input wire wea_p,  // write enable, should be positive when writing mac address

    // All NUD signals will be hold for one cycle after the probe timer reaches the PROBE_LIMIT
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


  reg [ENTRY_ADDR_WIDTH-1:0] update_addr;  // write address, used for updating
  reg [ENTRY_ADDR_WIDTH-1:0] insert_addr;  // write address, used for inserting

  // next replace address. If the table is full and query fails, this is the address to replace.
  reg [ENTRY_ADDR_WIDTH-1:0] next_replace_addr;

  // insertability flag
  reg insertable;

  // updatablitity flag
  reg updatable;

  // =================== CAM entry query (R0), higher address first =============
  always_comb begin : CAM_R
    r_exists_0   = 0;
    r_MAC_addr_0 = 0;
    r_port_id_0  = 0;
    for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
      if (
           neighbor_cache_entries[i].valid &&
           (neighbor_cache_entries[i].IPv6_addr == r_IPv6_addr_0)
          ) begin
        // read MAC address
        r_exists_0   = 1;
        r_MAC_addr_0 = neighbor_cache_entries[i].MAC_addr;
        r_port_id_0  = neighbor_cache_entries[i].port_id;
      end
    end
  end
  // ===========================================================================

  // =================== CAM entry query (R1), higher address first =============
  always_comb begin : CAM_R1
    r_exists_1   = 0;
    r_MAC_addr_1 = 0;
    r_port_id_1  = 0;
    for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
      if (
           neighbor_cache_entries[i].valid &&
           (neighbor_cache_entries[i].IPv6_addr == r_IPv6_addr_1)
          ) begin
        // read MAC address
        r_exists_1   = 1;
        r_MAC_addr_1 = neighbor_cache_entries[i].MAC_addr;
        r_port_id_1  = neighbor_cache_entries[i].port_id;
      end
    end
  end


  // =================== CAM entry query (W), higher address first =============
  always_comb begin : CAM_W
    updatable   = 0;
    update_addr = 0;
    if (wea_p) begin  // write
      for (int i = 0; i < NUM_ENTRIES; i = i + 1) begin
        if(
            neighbor_cache_entries[i].valid &&
            (neighbor_cache_entries[i].IPv6_addr == w_IPv6_addr)
          ) begin
          // update MAC address
          updatable   = 1;
          update_addr = i;
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
      if (wea_p) begin
        if (updatable) begin
          // update MAC address and port id
          neighbor_cache_entries[update_addr].MAC_addr <= w_MAC_addr;
          neighbor_cache_entries[update_addr].port_id  <= w_port_id;
        end else if (insertable) begin
          // insert new entry
          neighbor_cache_entries[insert_addr].IPv6_addr <= w_IPv6_addr;
          neighbor_cache_entries[insert_addr].MAC_addr  <= w_MAC_addr;
          neighbor_cache_entries[insert_addr].port_id   <= w_port_id;
        end else begin
          // replace entry
          neighbor_cache_entries[next_replace_addr].IPv6_addr <= w_IPv6_addr;
          neighbor_cache_entries[next_replace_addr].MAC_addr  <= w_MAC_addr;
          neighbor_cache_entries[next_replace_addr].port_id   <= w_port_id;
          next_replace_addr                                   <= next_replace_addr + 1;
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
        if (wea_p) begin
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
            if (i == next_replace_addr) begin
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
          // NOT in save state
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
      if (
           neighbor_cache_entries[i].valid &&
           (neighbor_cache_entries[i].reachable_timer == PROBE_LIMIT)
          ) begin
        nud_probe = 1;
        probe_IPv6_addr = neighbor_cache_entries[i].IPv6_addr;
        probe_port_id = neighbor_cache_entries[i].port_id;
      end
    end
  end
  // ===========================================================================


endmodule
