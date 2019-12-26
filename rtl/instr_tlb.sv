`include "config.sv"

module instr_tlb (
    input   [`VADDR_WIDTH - 1:0]    i_vaddr,
    input   [`ASID_WIDTH - 1:0]     i_asid,
    
    output  [`PADDR_WIDTH - 1:0]    o_paddr,
    output                          o_hit,
    
    input   i_clk,
    input   i_rst_n
);

// A dummy ITLB
assign o_paddr = i_vaddr;
assign o_hit = 1'b1;

endmodule

