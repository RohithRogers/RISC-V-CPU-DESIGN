`timescale 1ns/1ps

module core(
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc_out
);

    // PC / IF
    wire [31:0] pc;
    wire        branch_taken;
    wire [31:0] branch_target;
    wire        jal, jalr;
    wire [31:0] jal_target, jalr_target;

    assign pc_out = pc;

    programcounter pc_reg (
        .clk(clk),
        .reset(reset),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .jal(jal),
        .jalr(jalr),
        .jal_target(jal_target),
        .jalr_target(jalr_target),
        .pc(pc)
    );

    // Instruction memory / fetch
    wire [31:0] instruction;

    instr_mem imem (
        .pc(pc),
        .instruction(instruction)
    );

    // Decode outputs
    wire [4:0]  rs1_addr;
    wire [4:0]  rs2_addr;
    wire [4:0]  rd_addr;
    wire [6:0]  opcode;
    wire [6:0]  funct7;
    wire [2:0]  funct3;
    wire [31:0] immediate;

    instr_decode id (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd_addr),
        .funct3(funct3),
        .rs1(rs1_addr),
        .rs2(rs2_addr),
        .funct7(funct7),
        .immediate(immediate)
    );

    // Register file
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // Write-back wires
    wire        reg_write;
    wire [31:0] wb_data;
    wire        mem_to_reg;

    registers regs (
        .clk(clk),
        .we(reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(wb_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Control signals
    wire        branch;
    wire        mem_read;
    wire        mem_write;
    wire        alu_src;
    wire [3:0]  alu_op;
    // mem_to_reg declared earlier as wire; comes from control unit

    control_unit cu (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jal(jal),
        .jalr(jalr)
    );

    // ALU inputs (AUIPC / LUI support)
    wire is_auipc = (opcode == 7'b0010111);
    wire is_lui   = (opcode == 7'b0110111);

    wire [31:0] alu_a = (is_auipc) ? pc : rs1_data;      // AUIPC uses PC + imm
    wire [31:0] alu_b = (alu_src) ? immediate : rs2_data;

    wire [31:0] alu_result;
    wire        alu_zero;

    ALU alu_unit (
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    // Branch unit (pass register values, not addresses)
    branch_unit bu (
        .branch(branch),
        .rs1(rs1_data),
        .rs2(rs2_data),
        .funct3(funct3),
        .branch_taken(branch_taken)
    );

    // Branch and Jump target calculation (use immediate produced by decode)
    assign branch_target = pc + immediate;                       // B-type imm expected
    assign jal_target    = pc + immediate;                       // J-type imm expected
    assign jalr_target   = (rs1_data + immediate) & 32'hfffffffe; // JALR: rs1 + imm, LSB=0

    // Data memory
    wire [31:0] mem_read_data;

    data_mem dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(funct3),
        .address(alu_result),
        .write_data(rs2_data),
        .read_data(mem_read_data)
    );

    // Writeback selection
    wire [31:0] pc_plus4 = pc + 32'd4;
    wire [31:0] lui_value = immediate; // decode must supply U-type immediate as {inst[31:12],12'b0}

    assign wb_data = (reg_write && (jal || jalr)) ? pc_plus4 :
                     (reg_write && is_lui)              ? lui_value :
                     (reg_write && mem_to_reg)          ? mem_read_data :
                     (reg_write)                        ? alu_result :
                                                          32'd0;

endmodule
