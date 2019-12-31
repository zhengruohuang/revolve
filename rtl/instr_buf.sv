`include "config.sv"
`include "types.sv"

`include "lib/fifo_2i2o.sv"

module instr_buf (
    input   decoded_instr_t     i_instrs    [0:`FETCH_WIDTH - 1],
    input                       i_dequeue,
    input                       i_flush,
    
    output  decoded_instr_t     o_instrs    [0:`FETCH_WIDTH - 1],
    output                      o_stall,
    
    input   i_clk,
    input   i_rst_n
);
    genvar i;

    // FIFO control signals
    wire [`FETCH_WIDTH - 1:0]           w_e;
    wire [$bits(decoded_instr_t) - 2:0] w_data [0:`FETCH_WIDTH - 1];
    wire [`FETCH_WIDTH - 1:0]           w_ack;

    wire [`FETCH_WIDTH - 1:0]           r_e;
    wire [$bits(decoded_instr_t) - 2:0] r_data [0:`FETCH_WIDTH - 1];
    wire [`FETCH_WIDTH - 1:0]           r_valid;
    wire [`FETCH_WIDTH - 1:0]           r_ack;

    wire                                fifo_avail;
    wire                                fifo_full;
    wire                                fifo_empty;

    assign w_e = fifo_avail ? { `FETCH_WIDTH{1'b1} } : { `FETCH_WIDTH{1'b0} };
    assign r_e = i_dequeue  ? { `FETCH_WIDTH{1'b1} } : { `FETCH_WIDTH{1'b0} };

    generate
        for (i = 0; i < `FETCH_WIDTH; i = i + 1) begin
            assign w_data[i] = i_instrs[i][$bits(decoded_instr_t) - 1:1];
        end
    endgenerate

    // Generate output signals
    assign o_stall = ~fifo_avail;

    generate
        for (i = 0; i < `FETCH_WIDTH; i = i + 1) begin
            assign o_instrs[i] = { r_data[i], r_valid[i] };
        end
    endgenerate

    // The 2-in-2-out FIFO
    fifo_2i2o # (
        .WIDTH          ($bits(decoded_instr_t) - 1),
        .DEPTH          (8),
        .W_CNT          (`FETCH_WIDTH),
        .R_CNT          (`FETCH_WIDTH),
        .ALWAYS_READ    (0)
    ) the_buf (
        .i_w_e          (w_e),
        .i_w_data       (w_data),
        .o_w_ack        (w_ack),
        
        .i_r_e          (r_e),
        .o_r_data       (r_data),
        .o_r_valid      (r_valid),
        .o_r_ack        (r_ack),
        
        .i_flush        (i_flush),
        .o_avail        (fifo_avail),
        .o_full         (fifo_full),
        .o_empty        (fifo_empty),
        
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

endmodule

