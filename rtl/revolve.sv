`include "config.sv"
`include "types.sv"

`include "instr_fetch.sv"
`include "instr_fetch2.sv"

module revolve (
    input i_clk,
    input i_rst_n
);

////////////////////////////////////////////////////////////////////////////////
// Iinstr Fetch 1
////////////////////////////////////////////////////////////////////////////////
wire    [`PADDR_WIDTH - 1:0]    if1_paddr;
wire    [1:0]                   if1_valids  [0:`FETCH_WIDTH - 1];

instr_fetch if1 (
    .o_paddr    (if1_paddr),
    .o_valids   (if1_valids),
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n)
);

////////////////////////////////////////////////////////////////////////////////
// Iinstr Fetch 2
////////////////////////////////////////////////////////////////////////////////
fetched_instr_t                 if2_instrs    [0:`FETCH_WIDTH - 1];

instr_fetch2 if2 (
    .i_paddr    (if1_paddr),
    .i_valids   (if1_valids),
    .o_instrs   (if2_instrs),
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n)
);


////////////////////////////////////////////////////////////////////////////////
// Irrelevent
////////////////////////////////////////////////////////////////////////////////
reg [31:0] counter;

always @(posedge i_clk or negedge i_rst_n) begin
    if (i_rst_n == 1'b0) begin
        counter <= 32'b0;
    end else begin
        counter <= counter + 32'b1;
    end
end

endmodule

