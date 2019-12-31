`include "config.sv"
`include "types.sv"

`include "instr_decompressor.sv"

// FIXME: The following code assumes 2-wide fetch

module instr_align (
    input   [`VADDR_WIDTH - 1:0]    i_pc,
    input   fetched_instr_t         i_instrs    [0:`FETCH_WIDTH - 1],
    
    input                           i_stall,
    input                           i_flush,
    
    output  [`VADDR_WIDTH - 1:0]    o_pc_base,
    output  aligned_instr_t         o_instrs    [0:`FETCH_WIDTH - 1],
    output                          o_stall,
    
    input   i_clk,
    input   i_rst_n
);

// An extra cycle is needed when
//  (a) There is one compressed instr in the first slot, or
//  (b) First slot is valid and there is one compressed instr in the second slot
// Note that in the second case we only need to check the second 16-bit subslot
// because a valid first slot and a valid second half in the second slot implies
// a valid first half in the second slot
wire need_extra_cycle =
    (i_instrs[0].valid[1]       & i_instrs[0].instr[1:0] != 2'b11) |
    (i_instrs[0].valid != 2'b0  & i_instrs[1].valid[1] & i_instrs[1].instr[1:0] != 2'b11);

// Are we in the initial cycle or in the extra one?
reg in_extra_cycle;

always @ (posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        in_extra_cycle <= 1'b0;
    end
    
    else begin
        if (i_flush) begin
            in_extra_cycle <= 1'b0;
        end else if (i_stall) begin
            in_extra_cycle <= in_extra_cycle;
        end else if (in_extra_cycle) begin
            in_extra_cycle <= 1'b0;
        end else begin
            in_extra_cycle <= 1'b1;
        end
    end
end

// Propagate PC
reg [`VADDR_WIDTH - 1:0] pc_base;
assign o_pc_base = { pc_base[`VADDR_WIDTH - 1:3], 3'b000 };

always @ (posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        pc_base <= 0;
    end
    
    else begin
        if (i_flush) begin
            pc_base <= 0;
        end else if (i_stall) begin
            pc_base <= pc_base;
        end else begin
            pc_base <= i_pc;
        end
    end
end

// Decompressors
wire [15:0] comp_instr0 = ~in_extra_cycle & i_instrs[0].valid[1] ? i_instrs[0].instr[31:16] : i_instrs[1].instr[31:16];
wire [15:0] comp_instr1 = ~in_extra_cycle & i_instrs[0].valid[1] ? i_instrs[0].instr[15:0]  : i_instrs[1].instr[15:0];

wire [`INSTR_WIDTH - 1:0]   decomp_instrs   [0:`FETCH_WIDTH - 1];
wire                        decomp_unkowns  [0:`FETCH_WIDTH - 1];

instr_decompressor idecomp0 (
    .i_instr    (comp_instr0),
    .o_instr    (decomp_instrs[0]),
    .o_unknown  (decomp_unkowns[0])
);

instr_decompressor idecomp1 (
    .i_instr    (comp_instr1),
    .o_instr    (decomp_instrs[1]),
    .o_unknown  (decomp_unkowns[1])
);

// Align the instrs
aligned_instr_t             aligned_instrs  [0:`FETCH_WIDTH - 1];
assign                      o_instrs[0]     = aligned_instrs[0];
assign                      o_instrs[1]     = aligned_instrs[1];

wire [`INSTR_WIDTH - 1:0]   EMPTY_INSTR     = 0;
aligned_instr_t             INVALID_INSTR   = { 3'b0, EMPTY_INSTR, 1'b0 };

always @ (posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        aligned_instrs[0] <= INVALID_INSTR;
        aligned_instrs[1] <= INVALID_INSTR;
    end
    
    else begin
        if (i_flush) begin
            aligned_instrs[0] <= INVALID_INSTR;
            aligned_instrs[1] <= INVALID_INSTR;
        end else if (i_stall) begin
            aligned_instrs[0] <= aligned_instrs[0];
            aligned_instrs[1] <= aligned_instrs[1];
        end
        
        // First cycle and slot1
        else if (~in_extra_cycle & i_instrs[0].valid[1]) begin
            // Only one 2B instr
            if (~i_instrs[0].valid[0]) begin
                //aligned_instrs[0] <= { 3'h2, { 16'b0, i_instrs[0][15:0]  }, 1'b1 };
                aligned_instrs[0] <= { 3'h2, decomp_instrs[1], 1'b1 };
                aligned_instrs[1] <= INVALID_INSTR;
            end
            
            // Two 4B instrs
            else if (i_instrs[0].instr[1:0] == 2'b11) begin
                aligned_instrs[0] <= { 3'h0, i_instrs[0].instr, 1'b1 };
                aligned_instrs[1] <= { 3'h4, i_instrs[1].instr, 1'b1 };
            end
            
            // Two 2B instrs
            else begin
                //aligned_instrs[0] <= { 3'h0, { 16'b0, i_instrs[0][31:16] }, 1'b1 };
                //aligned_instrs[1] <= { 3'h2, { 16'b0, i_instrs[0][15:0]  }, 1'b1 };
                aligned_instrs[0] <= { 3'h0, decomp_instrs[0], 1'b1 };
                aligned_instrs[1] <= { 3'h2, decomp_instrs[1], 1'b1 };
            end
        end
        
        // Second cycle, or first cycle but slot2
        else begin
            // One 4B instr
            if (i_instrs[1].instr[1:0] == 2'b11) begin
                aligned_instrs[0] <= { 3'h4, i_instrs[1].instr, 1'b1 };
                aligned_instrs[1] <= INVALID_INSTR;
            end
            
            // Two 2B instrs
            else begin
                //aligned_instrs[0] <= { 3'h4, { 16'b0, i_instrs[1][31:16] }, 1'b1 };
                //aligned_instrs[1] <= { 3'h6, { 16'b0, i_instrs[1][15:0]  }, 1'b1 };
                aligned_instrs[0] <= { 3'h4, decomp_instrs[0], 1'b1 };
                aligned_instrs[1] <= { 3'h6, decomp_instrs[1], 1'b1 };
            end
        end
    end
end

// Fetch has to be stalled if an extra cycle is needed
assign o_stall = ~in_extra_cycle & need_extra_cycle;

endmodule

