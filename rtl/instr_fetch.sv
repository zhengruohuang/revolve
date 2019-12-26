`include "config.sv"

`include "instr_tlb.sv"
`include "instr_cache_tag.sv"

module instr_fetch (
    output reg  [`PADDR_WIDTH - 1:0]    o_paddr,
    output reg  [1:0]                   o_valids    [0:`FETCH_WIDTH - 1],   // Two compressed instrs per 4B slot
    input       i_clk,
    input       i_rst_n
);

reg     [`VADDR_WIDTH - 1:0]    pc;
reg     [1:0]                   pc_valids   [0:`FETCH_WIDTH - 1];
wire    [`VADDR_WIDTH - 3:0]    pc_updater = `FETCH_WIDTH;

reg     [`ASID_WIDTH - 1:0]     asid;

// Update PC and valid map
always @ (posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        pc <= 0;
        for (int i = 0; i < `FETCH_WIDTH; i++) begin
            pc_valids[i] <= 2'b11;
        end
    end else begin
        pc <= { pc[`VADDR_WIDTH - 1:2] + pc_updater, 2'b0 };
        for (int i = 0; i < `FETCH_WIDTH; i++) begin
            pc_valids[i] <= 2'b11;
        end
    end
end

// Parallel access of ITLB and ICacheTag
wire    [`PADDR_WIDTH - 1:0]    itlb_trans_paddr;
wire                            itlb_hit;
wire                            icache_hit;

instr_tlb itlb (
    .i_vaddr    (pc),
    .i_asid     (asid),
    .o_paddr    (itlb_trans_paddr),
    .o_hit      (itlb_hit),
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n)
);

instr_cache_tag icache_tag (
    .i_vaddr    (pc),
    .i_asid     (asid),
    .i_paddr    (itlb_trans_paddr),
    .i_tlb_hit  (itlb_hit),
    .o_hit      (icache_hit),
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n)
);

// Update outputs
always @ (posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        o_paddr <= 0;
        for (int i = 0; i < `FETCH_WIDTH; i++) begin
            o_valids[i] <= 2'b0;
        end
    end else begin
        o_paddr <= icache_hit ? itlb_trans_paddr : 0;
        for (int i = 0; i < `FETCH_WIDTH; i++) begin
            pc_valids[i] <= icache_hit ? pc_valids[i] : 2'b0;
        end
    end
end

endmodule

