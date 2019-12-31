`include "config.sv"
`include "types.sv"

module instr_tlb (
    input   [`VADDR_WIDTH - 1:0]    i_vaddr/*verilator public*/,
    output  tlb_entry_t             o_itlb          [0:`ITLB_ASSOC - 1],
    
    input   i_clk,
    input   i_rst_n
);

    tlb_entry_t itlb [0:`ITLB_ASSOC - 1]/*verilator public*/;

    // Dummy ITLB
    assign o_itlb = itlb;

    always @ (posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            for (int i = 0; i < `ITLB_ASSOC; i++) begin
                itlb[i] <= 0;
            end
        end
    end

endmodule

