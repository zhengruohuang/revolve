`include "config.sv"
`include "types.sv"

`include "instr_decoder_simple.sv"
//`include "instr_decoder_complex.sv"

module instr_decode (
    input   [`VADDR_WIDTH - 1:0]    i_pc_base,
    input   aligned_instr_t         i_instrs    [0:`FETCH_WIDTH - 1],
    
    input                           i_stall,
    input                           i_flush,
    
    output  decoded_instr_t         o_instrs    [0:`FETCH_WIDTH - 1],
    output                          o_stall,
    
    input   i_clk,
    input   i_rst_n
);

    genvar i;

    // Simple decoder control signals
    aligned_instr_t         raw_instrs_simple       [0:`FETCH_WIDTH - 1];
    decoded_fields_t        decoded_fields_simple   [0:`FETCH_WIDTH - 1];
    decoded_instr_t         decoded_instrs_simple   [0:`FETCH_WIDTH - 1];
    wire                    is_complex              [0:`FETCH_WIDTH - 1];

    // The simple decoders
    generate
        for (i = 0; i < `FETCH_WIDTH; i = i + 1) begin
            assign raw_instrs_simple[i] = i_instrs[i];
            
            assign decoded_instrs_simple[i].pc = { i_pc_base[31:3], i_instrs[i].pc_offset };
            assign decoded_instrs_simple[i].npc = 32'b0;
            assign decoded_instrs_simple[i].fields = decoded_fields_simple[i];
            assign decoded_instrs_simple[i].valid = i_instrs[i].valid;
            
            assign o_instrs[i] = i_flush ? '0 : decoded_instrs_simple[i];
            
            instr_decoder_simple simple_decoder (
                .i_instr    (raw_instrs_simple[i].instr),
                .o_instr    (decoded_fields_simple[i]),
                .o_complex  (is_complex[i])
            );
        end
    endgenerate

    // Other output signals
    assign o_stall = 1'b0;

/*
 * Since we are not supporting AMO or FP right now,
 * complex decoders are not needed
 *
// Internal complex decoding index - which complex instr is being decoded
reg     [$clog2[`FETCH_WIDTH] - 1:0]    complex_idx;

// Complex decoder control signals
fetched_instr_t                 raw_instrs_complex      [0:`FETCH_WIDTH - 1];
reg     [1:0]                   complex_step;
decoded_instr_t                 decoded_instrs_complex  [0:`FETCH_WIDTH - 1];
wire    [`FETCH_WIDTH - 1:0]    not_complex;
wire    [`FETCH_WIDTH - 1:0]    more_complex;

// The complex decoders
generate
    for (i = 0; i < FETCH_WIDTH; i = i + 1) begin
        instr_decoder_complex complex_decoder (
            .i_instr        (raw_instrs_complex[i].instr),
            .i_step         (complex_step + i),
            .o_instr        (decoded_instrs_complex[i]),
            .o_not_complex  (not_complex[i]),
            .o_more         (more_complex[i])
        );
    end
endgenerate

// Generate output signals
reg     decoded_instr_t     decoded_instrs  [0:`FETCH_WIDTH - 1];
reg                         stall_fetch;

assign  o_instrs = decoded_instrs;
assign  o_stall = stall_fetch;

always_comb begin
    case ({ i_instrs[0].valid, i_instrs[1].valid })
    2'b00: stall_fetch = 1'b0;
    2'b10: begin
        if (~is_complex[0]) begin
            stall_fetch = 1'b0;
        end else begin
            stall_fetch = more_complex[0] & more_complex[1];
        end
    end
    2'b01: begin
        stall_fetch = 1'b1;
        $error("Should never happen!");
    end
    2'b11: begin
        case ({ is_complex[0], is_complex[1] })
        2'b00: stall_fetch = 1'b0;
        2'b10: stall_fetch = complex_idx == 1'b1;
        2'b01: stall_fetch = more_complex[0] & more_complex[1];
        2'b11: stall_fetch = (complex_idx == 1'b1) & more_complex[0] & more_complex[1];
        endcase
    end
    endcase
end

always @ (posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        decoded_instrs[0] <= '0;
        decoded_instrs[1] <= '0;
        complex_idx <= '0;
        complex_step <= '0;
    end
    
    else begin
        if (i_flush) begin
            decoded_instrs[0] <= '0;
            decoded_instrs[1] <= '0;
            complex_idx <= '0;
            complex_step <= '0;
        end else begin
            case ({ i_instrs[0].valid, i_instrs[1].valid })
            2'b00: begin
                decoded_instrs[0] <= '0;
                decoded_instrs[1] <= '0;
                complex_idx <= '0;
                complex_step <= '0;
            end
            2'b10: begin
                if (~is_complex[0]) begin
                    decoded_instrs[0] <= decoded_instrs_simple[0];
                    decoded_instrs[1] <= '0;
                    complex_idx <= '0;
                    complex_step <= '0;
                end else begin
                    decoded_instrs[0] <= decoded_instrs_complex[0];
                    decoded_instrs[1] <= not_complex[1] ? '0 : decoded_instrs_complex[1];
                    if (more_complex[0] & more_complex[1]) begin
                        complex_step <= complex_step + 2;
                        complex_idx <= '0;
                    end else begin
                        complex_step <= '0;
                        complex_idx <= '0;
                    end
                end
            end
            2'b01: begin
                $error("Should never happen!");
            end
            2'b11: begin
                case ({ is_complex[0], is_complex[1] })
                2'b00: begin
                    decoded_instrs[0] <= decoded_instrs_simple[0];
                    decoded_instrs[1] <= decoded_instrs_simple[1];
                    complex_idx <= '0;
                    complex_step <= '0;
                end
                2'b10: begin
                    if (complex_idx == 1'b1) begin
                        decoded_instrs[0] <= decoded_instrs_simple[1];
                        decoded_instrs[1] <= '0;
                        complex_idx <= '0;
                        complex_step <= '0;
                    end else begin
                        decoded_instrs[0] <= decoded_instrs_complex[0];
                        decoded_instrs[1] <= not_complex[1] ? '0 : decoded_instrs_complex[1];
                        if (more_complex[0] & more_complex[1]) begin
                            complex_step <= complex_step + 2;
                            complex_idx <= '0;
                        end else begin
                            complex_step <= '0;
                            complex_idx <= '1;
                        end
                    end
                end
                2'b01: begin
                    if (complex_idx == 1'b0) begin
                        
                    end
                    stall_fetch = more_complex[0] & more_complex[1];
                end
                2'b11: begin
                    stall_fetch = (complex_idx == 1'b1) & more_complex[0] & more_complex[1];
                end
                endcase
            end
            endcase
        end
    end
end
*/

endmodule

