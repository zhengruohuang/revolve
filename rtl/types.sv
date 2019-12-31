`ifndef __TYPES_SV__
`define __TYPES_SV__

`include "config.sv"

/*
 * Program State
 */
typedef struct packed {
    bit [`ASID_WIDTH - 1:0]     asid;
    bit [2:0]                   mode;
} program_state_t;

/*
 * ITLB and ICache
 */
`define VPN_WIDTH   (`VADDR_WIDTH - `MIN_PAGE_BITS)
`define PPN_WIDTH   (`PADDR_WIDTH - `MIN_PAGE_BITS)

typedef struct packed {
    bit [`VPN_WIDTH - 1:0]      vpn;
    bit [`PPN_WIDTH - 1:0]      ppn;
    bit                         valid;
} tlb_entry_t;

`define ICACHE_TAG_WIDTH    (`PADDR_WIDTH - `CACHELINE_BITS)
`define ICACHE_DATA_WIDTH   (`INSTR_WIDTH * `FETCH_WIDTH)

typedef struct packed {
    bit [`ICACHE_TAG_WIDTH - 1:0]   tag;
    bit                             valid;
} icache_tag_entry_t;

typedef struct packed {
    bit [`ICACHE_DATA_WIDTH - 1:0]  data;
} icache_data_unit_t;

/*
 * Instr Fetch
 */
typedef struct packed {
    bit [`INSTR_WIDTH - 1:0]    instr;
    bit [1:0]                   valid;  // Two compressed instrs per 4B slot
} fetched_instr_t;

typedef struct packed {
    bit [2:0]                   pc_offset;
    bit [`INSTR_WIDTH - 1:0]    instr;
    bit                         valid;  // Two compressed instrs per 4B slot
} aligned_instr_t;

typedef enum bit[2:0] {
    UNIT_ALU,
    UNIT_BR,
    UNIT_MEM,
    UNIT_MUL,
    UNIT_CSR,
    UNIT_FP
} decoded_unit_t;

typedef enum bit[3:0] {
    OP_ALU_ADD,
    OP_ALU_SUB,
    
    OP_ALU_MIN,
    OP_ALU_MAX,
    
    OP_ALU_AND,
    OP_ALU_OR,
    OP_ALU_XOR,
    
    OP_ALU_SLL,     // Shift left logical
    OP_ALU_SRL,     // Shift right logical
    OP_ALU_SRA,     // Shift right arithmetic
    
    OP_ALU_SLT,     // Set less than
    
    OP_ALU_FLUSH
} decoded_alu_op_t;

typedef enum bit[3:0] {
    OP_BR_BEQ,
    OP_BR_BLT,
    OP_BR_JALR,
    
    OP_BR_ECALL,
    OP_BR_EBREAK,
    
    OP_BR_TRAP_RET
} decoded_br_op_t;

typedef enum bit[3:0] {
    OP_MDU_MUL,
    OP_MDU_DIV,
    OP_MDU_REM
} decoded_mul_op_t;

typedef enum bit[3:0] {
    OP_CSR_SWAP,
    OP_CSR_READ_SET,
    OP_CSR_READ_CLEAR
} decoded_csr_op_t;

typedef enum bit[3:0] {
    OP_MEM_LOAD,
    OP_MEM_STORE,
    
    OP_MEM_FENCE,
    
    OP_MEM_LOAD_LINK,
    OP_MEM_STORE_COND,
    
    OP_MEM_LOAD_AMO,
    OP_MEM_STORE_AMO
} decoded_mem_op_t;

typedef union packed {
    decoded_alu_op_t alu;
    decoded_mul_op_t mul;
    decoded_csr_op_t csr;
    decoded_mem_op_t mem;
} decoded_op_t;

typedef enum bit[3:0] {
    EXCEPT_PC_MISALIGN,
    EXCEPT_PC_ACCESS_FAULT,
    EXCEPT_UNKNOW_INSTR,
    EXCEPT_BREAKPOINT,
    EXCEPT_LOAD_MISALIGN,
    EXCEPT_LOAD_ACCESS_FAULT,
    EXCEPT_STORE_MISALIGN,
    EXCEPT_STORE_ACCESS_FAULT,
    EXCEPT_ECALL_FROM_U,
    EXCEPT_ECALL_FROM_S,
    EXCEPT_RESERVED1,
    EXCEPT_ECALL_FROM_M,
    EXCEPT_ITLB_PAGE_FAULT,
    EXCEPT_LOAD_PAGE_FAULT,
    EXCEPT_RESERVED2,
    EXCEPT_STORE_PAGE_FAULT
} exception_t;

typedef struct packed {
    decoded_unit_t              unit;
    decoded_op_t                op;
    bit [1:0]                   op_size;
    bit [1:0]                   op_attri;
    bit                         has_rd;
    bit                         alt_rd;     // Use Rtmp as rd
    bit [4:0]                   rd;
    bit                         has_rs1;
    bit                         alt_rs1;    // Use PC for ALU, uimm for CSR
    bit [4:0]                   rs1;
    bit                         has_rs2;
    bit                         alt_rs2;    // Use Rtmp as rs2
    bit [4:0]                   rs2;
    bit                         has_imm;
    bit [31:0]                  imm;
    bit                         has_except;
    exception_t                 except;
    bit                         middle;     // Non-last micro-op of a complex instr, must be committed together with the concluding micro-op
    bit                         serial;     // Does not enter pipeline until ROB empty
} decoded_fields_t;

typedef struct packed {
    bit [`VADDR_WIDTH - 1:0]    pc;
    bit [`VADDR_WIDTH - 1:0]    npc;
    decoded_fields_t            fields;
    bit                         valid;
} decoded_instr_t;

`endif

