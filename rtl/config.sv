`ifndef __CONFIG_SV__
`define __CONFIG_SV__

`define DATA_WIDTH          32

`define MIN_PAGE_SIZE       4096
`define MIN_PAGE_BITS       12

`define VADDR_WIDTH         32
`define PADDR_WIDTH         32

`define MAX_VADDR_TAG_WIDTH 20
`define MAX_PADDR_TAG_WIDTH 20

`define INSTR_WIDTH         32

`define ASID_WIDTH          12

`define FETCH_WIDTH         2
`define FETCH_DATA_WIDTH    (`STD_INSTR_WIDTH * `FETCH_WIDTH)

`endif

