`include "config.sv"

module instr_cache_data (
    input   [`PADDR_WIDTH - 1:0]    i_paddr/*verilator public*/,
    output  [`INSTR_WIDTH - 1:0]    o_data      [0:`FETCH_WIDTH - 1],
    
    input   i_clk,
    input   i_rst_n
);

reg [`INSTR_WIDTH - 1:0] instrs [0:`FETCH_WIDTH - 1]/*verilator public*/;

// Dummy ICache data
assign o_data = instrs;

always @ (posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        for (int i = 0; i < `FETCH_WIDTH; i++) begin
            instrs[i] <= 0;
        end
    end
end

endmodule

