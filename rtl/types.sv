`ifndef __TYPES_SV__
`define __TYPES_SV__

`include "config.sv"

typedef struct packed {
    bit [`INSTR_WIDTH - 1:0]    instr;
    bit [1:0]                   valid;  // Two compressed instrs per 4B slot
} fetched_instr_t;

`endif

