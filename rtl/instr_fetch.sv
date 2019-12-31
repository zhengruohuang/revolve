`include "config.sv"

`include "instr_tlb.sv"
`include "instr_cache_tag.sv"
`include "instr_cache_data.sv"

module instr_fetch (
    input   [`VADDR_WIDTH - 1:0]    i_pc,
    input   program_state_t         i_pstate,
    
    input                           i_stall,
    input                           i_flush,
    
    output  [`VADDR_WIDTH - 1:0]    o_pc,
    output  tlb_entry_t             o_itlb          [0:`ITLB_ASSOC - 1],
    output  icache_tag_entry_t      o_icache_tag    [0:`ICACHE_ASSOC - 1],
    output  icache_data_unit_t      o_icache_data   [0:`ICACHE_ASSOC - 1],
    
    input   i_clk,
    input   i_rst_n
);

    // Propagate PC
    reg     [`VADDR_WIDTH - 1:0]    pc;
    assign  o_pc = pc;
    
    always @ (posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            pc <= '0;
        end
        
        else begin
            if (i_flush) begin
                pc <= '0;
            end else if (i_stall) begin
                pc <= pc;
            end else begin
                pc <= i_pc;
            end
        end
    end

    // RAMs
    wire    [`VADDR_WIDTH - 1:0]    ram_pc = i_stall ? pc : i_pc;

    // ITLB
    instr_tlb itlb (
        .i_vaddr        (ram_pc),
        .o_itlb         (o_itlb),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    // ICache Tag
    instr_cache_tag icache_tag (
        .i_vaddr        (ram_pc),
        .o_icache_tag   (o_icache_tag),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    // ICache Data
    instr_cache_data icache_data (
        .i_vaddr        (ram_pc),
        .o_icache_data  (o_icache_data),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

endmodule

