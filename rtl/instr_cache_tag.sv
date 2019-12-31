`include "config.sv"

module instr_cache_tag (
    input   [`VADDR_WIDTH - 1:0]    i_vaddr/*verilator public*/,
    output  icache_tag_entry_t      o_icache_tag    [0:`ICACHE_ASSOC - 1],
    
    input   i_clk,
    input   i_rst_n
);

    icache_tag_entry_t icache_tag [0:`ICACHE_ASSOC - 1]/*verilator public*/;

    // Dummy ICache tag
    assign o_icache_tag = icache_tag;

    always @ (posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            for (int i = 0; i < `ICACHE_ASSOC; i++) begin
                icache_tag[i] <= 0;
            end
        end
    end

endmodule

