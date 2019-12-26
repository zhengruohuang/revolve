`include "config.sv"

module instr_cache_tag (
    input   [`VADDR_WIDTH - 1:0]    i_vaddr,
    input   [`ASID_WIDTH - 1:0]     i_asid,
    input   [`PADDR_WIDTH - 1:0]    i_paddr,
    input                           i_tlb_hit,
    output                          o_hit,
    //output  [`MAX_VADDR_TAG_WIDTH - 1:0] ptag,
    
    input i_clk,
    input i_rst_n
);

// Dummy ICache tag that doesn't do anything
assign o_hit = i_tlb_hit & 1'b1;

endmodule

