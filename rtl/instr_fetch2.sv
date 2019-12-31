`include "config.sv"
`include "types.sv"

module instr_fetch2 (
    input   [`VADDR_WIDTH - 1:0]    i_pc,
    input   program_state_t         i_pstate,
    
    input                           i_stall,
    input                           i_flush,
    
    input   tlb_entry_t             i_itlb          [0:`ITLB_ASSOC - 1],
    input   icache_tag_entry_t      i_icache_tag    [0:`ICACHE_ASSOC - 1],
    input   icache_data_unit_t      i_icache_data   [0:`ICACHE_ASSOC - 1],
    
    output  [`VADDR_WIDTH - 1:0]    o_pc,
    output  fetched_instr_t         o_instrs        [0:`FETCH_WIDTH - 1],
    
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
    
    // Signals for hit/miss
    wire    [`VPN_WIDTH - 1:0]          pc_vpn = pc[`VADDR_WIDTH - 1:`MIN_PAGE_BITS];
    reg                                 itlb_hit;
    reg     [`PPN_WIDTH - 1:0]          itlb_ppn;
    wire    [`PADDR_WIDTH - 1:0]        pc_paddr = { itlb_ppn, pc[`MIN_PAGE_BITS - 1:0] };
    wire    [`ICACHE_TAG_WIDTH - 1:0]   pc_ptag = pc_paddr[`PADDR_WIDTH - 1:`PADDR_WIDTH - `ICACHE_TAG_WIDTH];
    reg                                 icache_hit;
    reg     [`ICACHE_DATA_WIDTH - 1:0]  icache_data;
    
    // Find out TLB hit/miss
    always_comb begin
        // TLB hit @ way 0
        if (i_itlb[0].valid && pc_vpn == i_itlb[0].vpn) begin
            itlb_hit = 1'b1;
            itlb_ppn = i_itlb[0].ppn;
        end
        
        // TLB hit @ way 1
        else if (i_itlb[1].valid && pc_vpn == i_itlb[1].vpn) begin
            itlb_hit = 1'b1;
            itlb_ppn = i_itlb[1].ppn;
        end
        
        // TLB miss
        else begin
            itlb_hit = 0;
            itlb_ppn = 0;
        end
    end
    
    // Find out ICache tag hit/miss
    always_comb begin
        // ICache hit @ way 0
        if (itlb_hit && i_icache_tag[0].valid && pc_ptag == i_icache_tag[0].tag) begin
            icache_hit = 1'b1;
            icache_data = i_icache_data[0].data;
        end
        
        // ICache hit @ way 1
        else if (itlb_hit && i_icache_tag[1].valid && pc_ptag == i_icache_tag[1].tag) begin
            icache_hit = 1'b1;
            icache_data = i_icache_data[1].data;
        end
        
        // ICache miss
        else begin
            icache_hit = 0;
            icache_data = 0;
        end
    end
    
    // Generate output signals
    fetched_instr_t     INVALID_INSTR   = { 32'b0, 2'b0 };
    fetched_instr_t     fetched_instrs  [0:`FETCH_WIDTH - 1];
    
    wire [1:0]          pc_valid        [0:`FETCH_WIDTH - 1];
    assign  pc_valid[0] = { ~i_pc[2] & ~i_pc[1], ~i_pc[2] };
    assign  pc_valid[1] = { ~i_pc[1], 1'b1 };
    
    always @ (posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            fetched_instrs[0] <= '0;
            fetched_instrs[1] <= '0;
        end
        
        else begin
            if (i_flush) begin
                fetched_instrs[0] <= '0;
                fetched_instrs[1] <= '0;
            end else if (i_stall) begin
                fetched_instrs[0] <= fetched_instrs[0];
                fetched_instrs[1] <= fetched_instrs[1];
            end else if (~icache_hit) begin
                fetched_instrs[0] <= INVALID_INSTR;
                fetched_instrs[1] <= INVALID_INSTR;
            end else begin
                fetched_instrs[0] <= { icache_data[63:32], pc_valid[0] };
                fetched_instrs[1] <= { icache_data[31:0],  pc_valid[1] };
            end
        end
    end

endmodule

