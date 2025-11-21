// control_unit.v - clean, explicit RV32I control
`timescale 1ns/1ps
module control_unit(
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg [3:0] alu_op,
    output reg       alu_src,
    output reg       mem_to_reg,
    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       branch,
    output reg       jal,
    output reg       jalr
);

always @(*) begin
    // default values
    alu_op     = 4'b0000;
    alu_src    = 1'b0;
    mem_to_reg = 1'b0;
    reg_write  = 1'b0;
    mem_read   = 1'b0;
    mem_write  = 1'b0;
    branch     = 1'b0;
    jal        = 1'b0;
    jalr       = 1'b0;

    case (opcode)
        // R-type (register-register)
        7'b0110011: begin
            reg_write = 1'b1;
            alu_src   = 1'b0;
            case ({funct7, funct3})
                10'b0000000_000: alu_op = 4'b0000; // ADD
                10'b0100000_000: alu_op = 4'b0001; // SUB
                10'b0000000_111: alu_op = 4'b0010; // AND
                10'b0000000_110: alu_op = 4'b0011; // OR
                10'b0000000_100: alu_op = 4'b0100; // XOR
                10'b0000000_010: alu_op = 4'b0101; // SLT
                10'b0000000_011: alu_op = 4'b0110; // SLTU
                10'b0000000_001: alu_op = 4'b0111; // SLL
                10'b0000000_101: alu_op = 4'b1000; // SRL
                10'b0100000_101: alu_op = 4'b1001; // SRA
                default: alu_op = 4'b0000;
            endcase
        end

        // I-type ALU (ADDI, XORI, ORI, ANDI, etc.)
        7'b0010011: begin
            reg_write = 1'b1;
            alu_src   = 1'b1;
            case (funct3)
                3'b000: alu_op = 4'b0000; // ADDI
                3'b010: alu_op = 4'b0101; // SLTI
                3'b011: alu_op = 4'b0110; // SLTIU
                3'b100: alu_op = 4'b0100; // XORI
                3'b110: alu_op = 4'b0011; // ORI
                3'b111: alu_op = 4'b0010; // ANDI
                3'b001: alu_op = 4'b0111; // SLLI
                3'b101: begin
                    if (funct7 == 7'b0000000)
                        alu_op = 4'b1000; // SRLI
                    else
                        alu_op = 4'b1001; // SRAI
                end
                default: alu_op = 4'b0000;
            endcase
        end

        // Loads
        7'b0000011: begin
            reg_write  = 1'b1;
            alu_src    = 1'b1;
            mem_read   = 1'b1;
            mem_to_reg = 1'b1;
            alu_op     = 4'b0000; // ADD for address calc
        end

        // Stores
        7'b0100011: begin
            alu_src   = 1'b1;
            mem_write = 1'b1;
            alu_op    = 4'b0000; // ADD for address calc
        end

        // Branches
        7'b1100011: begin
            branch = 1'b1;
            alu_op = 4'b0001; // SUB for compare (if used)
            // branch unit will use rs1/rs2 and funct3 to decide taken/not
        end

        // JAL
        7'b1101111: begin
            reg_write = 1'b1;
            jal       = 1'b1;
            // rd gets pc+4 (handled by core writeback logic)
        end

        // JALR
        7'b1100111: begin
            reg_write = 1'b1;
            jalr      = 1'b1;
            alu_src   = 1'b1; // for target calc if implemented via ALU
            alu_op    = 4'b0000;
        end

        // LUI
        7'b0110111: begin
            reg_write = 1'b1;
            // immediate is handled by decode; writeback uses immediate
        end

        // ---------------------------
        // AUIPC
        // ---------------------------
        7'b0010111: begin
            reg_write = 1'b1;
            alu_src   = 1'b1;   // <--- IMPORTANT: use immediate as ALU B input
            mem_read  = 1'b0;
            mem_write = 1'b0;
            mem_to_reg= 1'b0;
            branch    = 1'b0;
            jal       = 1'b0;
            jalr      = 1'b0;
            alu_op    = 4'b0000; // ADD for PC + imm
end


        default: begin
            // unknown opcode -> keep defaults (all zeros)
        end
    endcase
end

endmodule
