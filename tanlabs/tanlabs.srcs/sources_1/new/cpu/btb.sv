module btb(
    input wire clk,
    input wire rst_p,
    input wire [31:0] if_pc,
    input wire [31:0] id_pc,
    input wire [31:0] id_offset,
    input wire id_we,
    input wire id_wrong,
    output reg [31:0] predict_pc,
    output reg predict_bc
);

// BTB LINE STRUCTURE:
// | HISTORY |    PC   |   J_PC  |
// |  2 bit  | 32 bits | 32 bits |

logic [1:0][65:0] btb_mem = {66'b0, 66'b0};
logic [31:0] last_id_pc;
always_ff @(posedge clk) begin
    last_id_pc <= id_pc;
end

always_comb begin : BTB_PREDICT
    if (id_wrong) begin
        predict_pc = if_pc + 4;
        predict_bc = 0;
    end else if (if_pc == btb_mem[0][63:32] && btb_mem[0][65]) begin
        predict_pc = btb_mem[0][31:0];
        predict_bc = 1;
    end else if (if_pc == btb_mem[1][63:32] && btb_mem[1][65]) begin
        predict_pc = btb_mem[1][31:0];
        predict_bc = 1;
    end else begin
        predict_pc = if_pc + 4;
        predict_bc = 0;
    end
end

logic latest_branch = 1;
logic [1:0] id_match = 2'b10;

always_comb begin : BTB_COMP // For new branch instruction
    if (id_pc == btb_mem[0][63:32]) id_match = 2'b00;
    else if (id_pc == btb_mem[1][63:32]) id_match = 2'b01;
    else id_match = 2'b10;
end

always_ff @(posedge clk) begin : BTB_WRITE
    if (rst_p) begin
        btb_mem <= 0;
    end else begin
        if (id_we && (last_id_pc != id_pc)) begin
            if (id_match[1] == 0) begin
                latest_branch <= id_match[0];
                if (id_match == 2'd0) begin
                    btb_mem[0][65] <= (id_wrong) ? btb_mem[0][64] : btb_mem[0][65];
                    btb_mem[0][64] <= (id_wrong) ? ~btb_mem[0][65] : btb_mem[0][65];
                end else if (id_match == 2'd1) begin
                    btb_mem[1][65] <= (id_wrong) ? btb_mem[1][64] : btb_mem[1][65];
                    btb_mem[1][64] <= (id_wrong) ? ~btb_mem[1][65] : btb_mem[1][65];
                end
            end else begin
                if (latest_branch) begin
                    btb_mem[0] <= {id_wrong, ~id_wrong, id_pc, id_pc + id_offset}; // Default bc=id_taken, change to 0 instantly if changed branch.
                    latest_branch <= 0;
                end else begin
                    btb_mem[1] <= {id_wrong, ~id_wrong, id_pc, id_pc + id_offset}; // Default bc=id_taken, change to 0 instantly if changed branch.
                    latest_branch <= 1;
                end
            end
        end
    end
end

endmodule