`include "config.sv"
`include "types.sv"

module program_state (
    input                           i_stall,
    input                           i_flush,
    
    output  [`VADDR_WIDTH - 1:0]    o_pc,
    output  program_state_t         o_pstate,
    
    input   i_clk,
    input   i_rst_n
);

    reg     [`VADDR_WIDTH - 1:0]    pc;
    program_state_t                 pstate;

    assign  o_pc = pc;
    assign  o_pstate = pstate;

    always @ (posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            pc <= `INIT_PC;
        end
        
        else begin
            if (i_flush) begin
                pc <= pc;
            end else if (i_stall) begin
                pc <= pc;
            end else begin
                pc <= pc + 32'h8;
            end
        end
    end

    always @ (posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            pstate <= 0;
        end
    end

endmodule

