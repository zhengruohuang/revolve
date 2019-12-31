`ifndef __CONFIG_SV__
`define __CONFIG_SV__

`define RV32

`define DATA_WIDTH          32

`define MIN_PAGE_SIZE       4096
`define MIN_PAGE_BITS       12

`define VADDR_WIDTH         32
`define PADDR_WIDTH         32

`define INIT_PC             32'b0

`define CACHELINE_SIZE      32
`define CACHELINE_BITS      5

`define INSTR_WIDTH         32

`define ASID_WIDTH          12

`define ITLB_ASSOC          2
`define ICACHE_ASSOC        2

`define FETCH_WIDTH         2
`define FETCH_DATA_WIDTH    (`STD_INSTR_WIDTH * `FETCH_WIDTH)

`endif

