`include "config.sv"
`include "types.sv"

`include "program_state.sv"
`include "instr_fetch.sv"
`include "instr_fetch2.sv"
`include "instr_align.sv"
`include "instr_decode.sv"
`include "instr_buf.sv"

module revolve (
    input i_clk,
    input i_rst_n
);

    //--------------------------------------------------------------------------
    // Pipeline Stages
    //--------------------------------------------------------------------------
    // Fetch1
    // Fetch2
    // Align
    // Decode
    // Buf
    // Rename
    // Dispatch (Implicit)
    // Wakeup (Implicit)
    // Select (Implicit)
    // Issue
    // ALU / AGU -> Mem1 & LSQ1 -> Mem2 & LSQ2 -> Mem3
    // Writeback
    // Commit1
    // Commit2

    genvar i;

    //--------------------------------------------------------------------------
    // Program State
    //--------------------------------------------------------------------------
    wire                        to_ps_stall     = 1'b0;     // TODO
    wire                        to_ps_flush     = 1'b0;     // TODO
    wire [`VADDR_WIDTH - 1:0]   from_ps_pc;
    program_state_t             from_ps_pstate;
    
    program_state ps (
        .i_stall        (to_ps_stall),
        .i_flush        (to_ps_flush),
        .o_pc           (from_ps_pc),
        .o_pstate       (from_ps_pstate),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Fetch 1
    //--------------------------------------------------------------------------
    wire [`VADDR_WIDTH - 1:0]   to_if1_pc       = from_ps_pc;
    program_state_t             to_if1_ps       = from_ps_pstate;
    wire                        to_if1_stall    = 1'b0;     // TODO
    wire                        to_if1_flush    = 1'b0;     // TODO
    wire [`VADDR_WIDTH - 1:0]   from_if1_pc;
    tlb_entry_t                 from_if1_itlb           [0:`ITLB_ASSOC - 1];
    icache_tag_entry_t          from_if1_icache_tag     [0:`ICACHE_ASSOC - 1];
    icache_data_unit_t          from_if1_icache_data    [0:`ICACHE_ASSOC - 1];

    instr_fetch if1 (
        .i_pc           (to_if1_pc),
        .i_pstate       (to_if1_ps),
        .i_stall        (to_if1_stall),
        .i_flush        (to_if1_flush),
        .o_pc           (from_if1_pc),
        .o_itlb         (from_if1_itlb),
        .o_icache_tag   (from_if1_icache_tag),
        .o_icache_data  (from_if1_icache_data),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Fetch 2
    //--------------------------------------------------------------------------
    wire [`VADDR_WIDTH - 1:0]   to_if2_pc       = from_if1_pc;
    program_state_t             to_if2_ps       = from_ps_pstate;
    wire                        to_if2_stall    = 1'b0;     // TODO
    wire                        to_if2_flush    = 1'b0;     // TODO
    tlb_entry_t                 to_if2_itlb             [0:`ITLB_ASSOC - 1];
    icache_tag_entry_t          to_if2_icache_tag       [0:`ICACHE_ASSOC - 1];
    icache_data_unit_t          to_if2_icache_data      [0:`ICACHE_ASSOC - 1];
    wire [`VADDR_WIDTH - 1:0]   from_if2_pc;
    fetched_instr_t             from_if2_instrs         [0:`FETCH_WIDTH - 1];

    instr_fetch2 if2 (
        .i_pc           (to_if2_pc),
        .i_pstate       (to_if2_ps),
        .i_stall        (to_if2_stall),
        .i_flush        (to_if2_flush),
        .i_itlb         (to_if2_itlb),
        .i_icache_tag   (to_if2_icache_tag),
        .i_icache_data  (to_if2_icache_data),
        .o_pc           (from_if2_pc),
        .o_instrs       (from_if2_instrs),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Align
    //--------------------------------------------------------------------------
    wire [`VADDR_WIDTH - 1:0]   to_ia_pc        = from_if2_pc;
    fetched_instr_t             to_ia_instrs    [0:`FETCH_WIDTH - 1];
    wire                        to_ia_stall     = 1'b0;     // TODO
    wire                        to_ia_flush     = 1'b0;     // TODO
    wire [`VADDR_WIDTH - 1:0]   from_ia_pc_base;
    aligned_instr_t             from_ia_instrs  [0:`FETCH_WIDTH - 1];
    wire                        from_ia_stall;
    
    generate
        for (i = 0; i < `FETCH_WIDTH; i = i + 1) begin
            assign to_ia_instrs[i] = from_if2_instrs[i];
        end
    endgenerate
    
    instr_align ia (
        .i_pc           (to_ia_pc),
        .i_instrs       (to_ia_instrs),
        .i_stall        (to_ia_stall),
        .i_flush        (to_ia_flush),
        .o_pc_base      (from_ia_pc_base),
        .o_instrs       (from_ia_instrs),
        .o_stall        (from_ia_stall),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Decode
    //--------------------------------------------------------------------------
    wire [`VADDR_WIDTH - 1:0]   to_id_pc_base;
    aligned_instr_t             to_id_instrs    [0:`FETCH_WIDTH - 1];
    wire                        to_id_stall     = 1'b0;     // TODO
    wire                        to_id_flush     = 1'b0;     // TODO
    decoded_instr_t             from_id_instrs  [0:`FETCH_WIDTH - 1];
    wire                        from_id_stall;
    
    generate
        for (i = 0; i < `FETCH_WIDTH; i = i + 1) begin
            assign to_id_instrs[i] = from_ia_instrs[i];
        end
    endgenerate
    
    instr_decode id (
        .i_pc_base      (to_id_pc_base),
        .i_instrs       (to_id_instrs),
        .i_stall        (to_id_stall),
        .i_flush        (to_id_flush),
        .o_instrs       (from_id_instrs),
        .o_stall        (from_id_stall),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Instr Buf
    //--------------------------------------------------------------------------
    decoded_instr_t             to_ib_instrs    [0:`FETCH_WIDTH - 1];
    wire                        to_ib_dequeue   = 1'b1;     // TODO
    wire                        to_ib_flush     = 1'b0;     // TODO
    decoded_instr_t             from_ib_instrs  [0:`FETCH_WIDTH - 1];
    wire                        from_ib_stall;
    
    generate
        for (i = 0; i < `FETCH_WIDTH; i = i + 1) begin
            assign to_ib_instrs[i] = from_id_instrs[i];
        end
    endgenerate
    
    instr_buf ib (
        .i_instrs       (to_ib_instrs),
        .i_dequeue      (to_ib_dequeue),
        .i_flush        (to_ib_flush),
        .o_instrs       (from_ib_instrs),
        .o_stall        (from_ib_stall),
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n)
    );

    //--------------------------------------------------------------------------
    // Irrelevent
    //--------------------------------------------------------------------------
    reg [31:0] counter;
    
    always @ (posedge i_clk or negedge i_rst_n) begin
        if (i_rst_n == 1'b0) begin
            counter <= 32'b0;
        end else begin
            counter <= counter + 32'b1;
        end
    end

endmodule

