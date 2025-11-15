module control_unit(
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,

    output reg [3:0] alu_op,
    output reg alu_src,
    output reg mem_to_reg,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg branch,
    output reg jal,
    output reg jalr
);

always @(*) begin

    // Default control signals
    alu_src     = 0;
    mem_to_reg  = 0;
    reg_write   = 0;
    mem_read    = 0;
    mem_write   = 0;
    branch      = 0;
    jal         = 0;
    jalr        = 0;
    alu_op      = 4'b0000; // ADD

    case (opcode)

        // ---------------------------
        // R-Type
        // ---------------------------
        7'b0110011: begin
            reg_write = 1;
            alu_src   = 0;

            case ({funct7,funct3})
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
            endcase
        end

        // ---------------------------
        // Load
        // ---------------------------
        7'b0000011: begin
            reg_write  = 1;
            alu_src    = 1;
            mem_read   = 1;
            mem_to_reg = 1;
            alu_op     = 4'b0000; // ADD
        end

        // ---------------------------
        // Store
        // ---------------------------
        7'b0100011: begin
            alu_src   = 1;
            mem_write = 1;
            alu_op    = 4'b0000; // ADD
        end

        // ---------------------------
        // Branch
        // ---------------------------
        7'b1100011: begin
            branch    = 1;
            alu_op    = 4'b0001; // SUB for comparison
        end

        // ---------------------------
        // JAL
        // ---------------------------
        7'b1101111: begin
            reg_write = 1;
            jal       = 1;
        end

        // ---------------------------
        // JALR
        // ---------------------------
        7'b1100111: begin
            reg_write = 1;
            alu_src   = 1;
            jalr      = 1;
            alu_op    = 4'b0000; // ADD for rs1 + imm
        end

        // ---------------------------
        // I-Type ALU
        // ---------------------------
        7'b0010011: begin
            reg_write = 1;
            alu_src   = 1;

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
            endcase
        end

        // ---------------------------
        // LUI
        // ---------------------------
        7'b0110111: begin
            reg_write = 1;
            // ALU is not used
        end

        // ---------------------------
        // AUIPC
        // ---------------------------
        7'b0010111: begin
            reg_write = 1;
            // top-level ALU will compute PC + imm
        end

    endcase

end
endmodule
