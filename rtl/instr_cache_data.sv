`include "config.sv"
`include "types.sv"

module instr_cache_data (
    input   [`PADDR_WIDTH - 1:0]    i_vaddr/*verilator public*/,
    output  icache_data_unit_t      o_icache_data   [0:`ICACHE_ASSOC - 1],
    
    input   i_clk,
    input   i_rst_n
);

    icache_data_unit_t icache_data [0:`ICACHE_ASSOC - 1]/*verilator public*/;

    // Dummy ICache data
    assign o_icache_data = icache_data;

    always @ (posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            for (int i = 0; i < `ICACHE_ASSOC; i++) begin
                icache_data[i] <= 0;
            end
        end
    end

endmodule

