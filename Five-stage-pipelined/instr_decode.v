`timescale 1ns/1ps
module instr_decode(
    input  wire [31:0] instruction,
    output wire [6:0]  opcode,
    output wire [4:0]  rd,
    output wire [2:0]  funct3,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [6:0]  funct7,
    output reg  [31:0] immediate
);

    // simple fields as wires
    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign funct7 = instruction[31:25];

    // immediate extraction
    always @(*) begin
        case (opcode)
            // I-type: addi, slti, lw, jalr, etc.
            7'b0010011, // OP-IMM
            7'b0000011, // LOAD
            7'b1100111: // JALR
                immediate = {{20{instruction[31]}}, instruction[31:20]};

            // S-type: store
            7'b0100011:
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-type: branches (imm[12|10:5|4:1|11] << 1)
            7'b1100011:
                immediate = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};

            // U-type: LUI/AUIPC (imm[31:12] << 12)
            7'b0110111, // LUI
            7'b0010111: // AUIPC
                immediate = {instruction[31:12], 12'b0};

            // J-type: JAL (imm[20|10:1|11|19:12] << 1)
            7'b1101111:
                immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

            default:
                immediate = 32'd0;
        endcase
    end

endmodule
