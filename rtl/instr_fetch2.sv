`include "config.sv"
`include "types.sv"

`include "instr_cache_data.sv"

module instr_fetch2 (
    input       [`PADDR_WIDTH - 1:0]    i_paddr,
    input       [1:0]                   i_valids    [0:`FETCH_WIDTH - 1],
    output      fetched_instr_t         o_instrs    [0:`FETCH_WIDTH - 1],
    input       i_clk,
    input       i_rst_n
);

wire [`INSTR_WIDTH - 1:0] empty_instr = 0;
wire [`INSTR_WIDTH - 1:0] fetched_data [0:`FETCH_WIDTH - 1];

instr_cache_data icache_data (
    .i_paddr    (i_paddr),
    .o_data     (fetched_data),
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n)
);

always @ (posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        for (int i = 0; i < `FETCH_WIDTH; i++) begin
            o_instrs[i] <= { empty_instr, 2'b0 };
        end
    end else begin
        for (int i = 0; i < `FETCH_WIDTH; i++) begin
            o_instrs[i] <= { fetched_data[i], i_valids[i] };
        end
    end
end

endmodule

