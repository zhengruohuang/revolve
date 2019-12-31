`include "config.sv"
`include "types.sv"

module instr_decoder_complex (
    input   [`INSTR_WIDTH - 1:0]    i_instr,
    input   [1:0]                   i_step,
    output  decoded_instr_t         o_instr,
    output                          o_not_complex,
    output                          o_more
);

// Extract key fields
wire [6:0]  opcode  = i_instr[6:0];
wire [2:0]  opfunc  = i_instr[14:12];
wire [6:0]  opfext  = i_instr[31:25];
wire [4:0]  rs1     = i_instr[19:15];
wire [4:0]  rs2     = i_instr[24:20];
wire [4:0]  rd      = i_instr[11:7];
wire [11:0] imm_i   = i_instr[31:20];
wire [11:0] imm_s   = { i_instr[31:25], i_instr[11:7] };

// The decoded instr
decoded_instr_t decoded_instr;
reg bad_step;
reg has_more;

assign o_instr = decoded_instr;
assign o_more = has_more;
assign o_not_complex = bad_step;

// A const for unknown instr
decoded_instr_t UNKOWN_INSTR = '0;

// The actual decoder
always_comb begin
    decoded_instr = UNKOWN_INSTR;
    bad_step = 1'b1;
    has_more = 1'b0;
    
    case (opcode)
    // Atomic
    7'b0101111: begin
        case (i_step)
        // Step 0
        2'b00: begin
            bad_step = 1'b0;
            has_more = 1'b1;
            
            decoded_instr.has_rd = 1'b1;
            decoded_instr.has_rs1 = 1'b1;
            decoded_instr.rd = rd;
            decoded_instr.rs1 = rs1;
            decoded_instr.unit = UNIT_MEM;
            decoded_instr.op_size = opfunc[0] ? 2'b11 : 2'b10;
            decoded_instr.attri[1:0] = opfext[1:0];
            
            case (opfext[6:2])
            5'b00001,   // AMO_SWAP
            5'b00000,   // AMO_ADD
            5'b00100,   // AMO_XOR
            5'b01100,   // AMO_AND
            5'b01000,   // AMO_OR
            5'b10000,   // AMO_MIN
            5'b10100:   // AMO_MAX
            begin
                decoded_instr.op = OP_MEM_LOAD_AMO;
            end
            5'b11000,   // AMO_MIN_U
            5'b11100:   // AMO_MAX_U
            begin
                decoded_instr.op = OP_MEM_LOAD_AMO; // AMO_MIN_U
                decoded_instr.attri[0] = 1'b1;      // Unsigned
            end
            endcase
        end
        
        // Step 1
        2'b01: begin
            bad_step = 1'b0;
            has_more = 1'b1;
            
            decoded_instr.alt_rd = 1'b1;
            decoded_instr.has_rs1 = 1'b1;
            decoded_instr.has_rs1 = 1'b1;
            decoded_instr.rs1 = rd;
            decoded_instr.rs2 = rs2;
            decoded_instr.unit = UNIT_ALU;
            decoded_instr.op_size[0] = ~opfunc[0];  // 1 == 32-bit
            
            case (opfext[6:2])
            // AMO_SWAP
            5'b00001: begin
                decoded_instr.op = OP_ALU_ADD;
                decoded_instr.rs2 = '0;
            end
            
            5'b00000: decoded_instr.op = OP_ALU_ADD;
            5'b00100: decoded_instr.op = OP_ALU_XOR;
            5'b01100: decoded_instr.op = OP_ALU_AND;
            5'b01000: decoded_instr.op = OP_ALU_OR;
            5'b10000: decoded_instr.op = OP_ALU_MIN;
            5'b10100: decoded_instr.op = OP_ALU_MAX;
            
            // AMO_MIN_U
            5'b11000: begin
                decoded_instr.op = OP_ALU_MIN;
                decoded_instr.attri[0] = 1'b1;  // Unsigned
            end
            
            // AMO_MAX_U
            5'b11100: begin
                decoded_instr.op = OP_ALU_MAX;
                decoded_instr.attri[0] = 1'b1;  // Unsigned
            end
            endcase
        end
        
        // Step 2
        3'b10: begin
            bad_step = 1'b0;
            has_more = 1'b0;
            
            decoded_instr.use_rs1 = 1'b1;
            decoded_instr.alt_rs2 = 1'b1;
            decoded_instr.rs1 = rs1;
            decoded_instr.unit = UNIT_MEM;
            decoded_instr.op_size = opfunc[0] ? 2'b11 : 2'b10;
            decoded_instr.attri[1:0] = opfext[1:0];
            
            case (opfext[6:2])
            5'b00001,   // AMO_SWAP
            5'b00000,   // AMO_ADD
            5'b00100,   // AMO_XOR
            5'b01100,   // AMO_AND
            5'b01000,   // AMO_OR
            5'b10000,   // AMO_MIN
            5'b10100,   // AMO_MAX
            5'b11000,   // AMO_MIN_U
            5'b11100:   // AMO_MAX_U
            begin
                decoded_instr.op = OP_MEM_STORE_AMO;
            end
            endcase
        end
        endcase
    end
    
    // Unknown
    default: decoded_instr = UNKOWN_INSTR;
    endcase
end

endmodule

