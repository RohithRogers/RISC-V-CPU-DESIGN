module instr_decode(
    input wire [31:0] instruction,
    output wire [6:0] opcode,
    output wire [4:0] rd,
    output wire [2:0] funct3,
    output wire [4:0] rs1,
    output wire [4:0] rs2,
    output wire [6:0] funct7,
    output reg [31:0] immediate
);

    // Field extraction using assign (combinational wires)
    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign funct7 = instruction[31:25];
    
    // Immediate extraction (inside always block)
    always @(*) begin
        case (opcode)
            7'b0010011, // I-type ALU
            7'b0000011, // Loads
            7'b1100111: // JALR
                immediate = {{20{instruction[31]}}, instruction[31:20]};

            7'b0100011: // S-type
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            7'b1100011: // B-type
                immediate = {{19{instruction[31]}}, instruction[31], instruction[7],
                              instruction[30:25], instruction[11:8], 1'b0};

            7'b1101111: // J-type (JAL)
                immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                             instruction[20], instruction[30:21], 1'b0};

            7'b0110111, // LUI (U-type)
            7'b0010111: // AUIPC
                immediate = {instruction[31:12], 12'b0};

            default:
                immediate = 32'd0;
        endcase
    end

endmodule
