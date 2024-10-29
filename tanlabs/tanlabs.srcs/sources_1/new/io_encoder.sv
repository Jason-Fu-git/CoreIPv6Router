`timescale 1ns / 1ps

`include "frame_datapath.vh"

module in_encoder(
    input wire clk,
    input wire rst_p,
    input frame_beat in,
    input wire in_valid,
    input wire ns_ready,
    input wire na_ready,
    input wire fw_ready,
    output frame_beat out_ns,
    output frame_beat out_na,
    output frame_beat out_fw,
    output reg ns_valid,
    output reg na_valid,
    output reg fw_valid,
    output reg in_ready
);

    frame_beat in_reg;

    reg handling_ns;
    reg handling_na;
    reg handling_fw;

    wire first_ns;
    wire first_na;
    wire first_fw;

    assign first_ns = (in.data.ip6.next_hdr          == IP6_HDR_TYPE_ICMPv6                   )
                   && (in.data.ip6.p[7:0]            == ICMPv6_HDR_TYPE_NS                    )
                   && (in.data.ip6.hop_limit         == IP6_HDR_HOP_LIMIT_DEFAULT             )
                   && (in.data.ip6.p[15:8]           == 0                                     )
                   && ({in.data.ip6.payload_len[7:0], in.data.ip6.payload_len[15:8]} >= 16'd24)
                   && (in.data.ip6.payload_len[10:8] == 3'b000                                )
                   && (in.data.ip6.src               != 0                                     );
    
    assign first_na = (in.data.ip6.next_hdr          == IP6_HDR_TYPE_ICMPv6                   )
                   && (in.data.ip6.p[7:0]            == ICMPv6_HDR_TYPE_NA                    )
                   && (in.data.ip6.hop_limit         == IP6_HDR_HOP_LIMIT_DEFAULT             )
                   && (in.data.ip6.p[15:8]           == 0                                     )
                   && ({in.data.ip6.payload_len[7:0], in.data.ip6.payload_len[15:8]} >= 16'd24)
                   && (in.data.ip6.payload_len[10:8] == 3'b000                                )
                   && (in.data.ip6.src               != 0                                     );
    
    assign first_fw = (in.data.ip6.version == 6) && (in.data.ip6.hop_limit > 1);

    assign in_ready = !((handling_ns && !ns_ready) || (handling_na && !na_ready) || (handling_fw && !fw_ready));

    always_ff @(posedge clk) begin
        if (rst_p) begin
            in_reg <= 0;
            handling_ns <= 0;
            handling_na <= 0;
            handling_fw <= 0;
            ns_valid <= 0;
            na_valid <= 0;
            fw_valid <= 0;
        end else begin
            if (in_valid && in_ready) begin
                in_reg <= in;
                if (in.is_first) begin
                    if (first_ns) begin
                        handling_ns <= 1;
                        handling_na <= 0;
                        handling_fw <= 0;
                        ns_valid <= 1;
                        na_valid <= 0;
                        fw_valid <= 0;
                    end else if (first_na) begin
                        handling_ns <= 0;
                        handling_na <= 1;
                        handling_fw <= 0;
                        ns_valid <= 0;
                        na_valid <= 1;
                        fw_valid <= 0;
                    end else if (first_fw) begin
                        handling_ns <= 0;
                        handling_na <= 0;
                        handling_fw <= 1;
                        ns_valid <= 0;
                        na_valid <= 0;
                        fw_valid <= 1;
                    end else begin
                        handling_ns <= 0;
                        handling_na <= 0;
                        handling_fw <= 0;
                        ns_valid <= 0;
                        na_valid <= 0;
                        fw_valid <= 0;
                    end
                end else begin
                    if (handling_ns) begin
                        ns_valid <= 1;
                        na_valid <= 0;
                        fw_valid <= 0;
                    end else if (handling_na) begin
                        ns_valid <= 0;
                        na_valid <= 1;
                        fw_valid <= 0;
                    end else if (handling_fw) begin
                        ns_valid <= 0;
                        na_valid <= 0;
                        fw_valid <= 1;
                    end else begin
                        ns_valid <= 0;
                        na_valid <= 0;
                        fw_valid <= 0;
                    end
                end
            end else begin
                ns_valid <= 0;
                na_valid <= 0;
                fw_valid <= 0;
            end
        end
    end

    assign out_ns = ns_valid ? in_reg : 0;
    assign out_na = na_valid ? in_reg : 0;
    assign out_fw = fw_valid ? in_reg : 0;
    
endmodule

module out_encoder(
    input wire clk,
    input wire rst_p,
    input frame_beat in_ns,
    input frame_beat in_fw,
    input frame_beat in_nud,
    input wire ns_valid,
    input wire fw_valid,
    input wire nud_valid,
    input wire out_ready,
    output frame_beat out,
    output reg out_valid,
    output reg ns_ready,
    output reg fw_ready,
    output reg nud_ready
);

    reg handling_ns;
    reg handling_fw;
    reg handling_nud;

    wire idle;

    assign idle = (!handling_ns  || (out_ready && ns_valid  && in_ns.last ))
               && (!handling_fw  || (out_ready && fw_valid  && in_fw.last ))
               && (!handling_nud || (out_ready && nud_valid && in_nud.last));

    assign ns_ready  = idle ? (out_ready                           ) : (handling_ns  && out_ready);
    assign nud_ready = idle ? (out_ready && !ns_valid              ) : (handling_nud && out_ready);
    assign fw_ready  = idle ? (out_ready && !ns_valid && !nud_valid) : (handling_fw  && out_ready);

    always_ff @(posedge clk) begin
        if (rst_p) begin
            handling_ns <= 0;
            handling_fw <= 0;
            handling_nud <= 0;
        end else begin
            if (ns_valid && in_ns.is_first) begin
                handling_ns <= 1;
            end else if (nud_valid && in_nud.is_first) begin
                handling_nud <= 1;
            end else if (fw_valid && in_fw.is_first) begin
                handling_fw <= 1;
            end
            if (handling_ns && ns_valid && in_ns.last && out_ready) begin
                handling_ns <= 0;
            end else if (handling_nud && nud_valid && in_nud.last && out_ready) begin
                handling_nud <= 0;
            end else if (handling_fw && fw_valid && in_fw.last && out_ready) begin
                handling_fw <= 0;
            end
        end
    end

    always_comb begin
        out = handling_ns ? in_ns :
             (handling_nud ? in_nud :
             (handling_fw ? in_fw :
             (ns_valid ? in_ns :
             (nud_valid ? in_nud :
             (fw_valid ? in_fw : 0)))));
        out.valid = ((handling_ns || in_ns.is_first) && ns_valid)
                 || ((handling_nud || in_nud.is_first) && nud_valid)
                 || ((handling_fw || in_fw.is_first) && fw_valid);
        out_valid = out.valid;
    end

endmodule

module cache_encoder(
    input wire clk,
    input wire rst_p,
    input wire ns_valid,
    input wire na_valid,
    input cache_entry ns_in,
    input cache_entry na_in,
    output reg ns_ready,
    output reg na_ready,
    output cache_entry out,
    output reg wea_p
);

    assign ns_ready = 1'b1;
    assign na_ready = !ns_valid;
    assign out = ns_valid ? ns_in : (na_valid ? na_in : 0);
    assign wea_p = ns_valid || na_valid;

endmodule
