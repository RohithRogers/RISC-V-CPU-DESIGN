`timescale 1ns/1ps
module core(
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc_out
);

    // =========================
    // IF stage
    // =========================
    wire [31:0] pc;
    assign pc_out = pc;
    wire pc_write;

    // These come from EX stage
    wire        ex_branch_taken;
    wire [31:0] ex_branch_target;
    wire        ex_jal, ex_jalr;
    wire [31:0] ex_jal_target, ex_jalr_target;

    programcounter pc_reg (
        .clk(clk),
        .reset(reset),
        .pc_write(pc_write),
        .branch_taken(ex_branch_taken),
        .branch_target(ex_branch_target),
        .jal(ex_jal),
        .jalr(ex_jalr),
        .jal_target(ex_jal_target),
        .jalr_target(ex_jalr_target),
        .pc(pc)
    );

    // Unified memory (instruction + data)
    wire [31:0] instruction;
    wire [31:0] mem_read_data;

    // MEM stage addr/data/control (will come from EX/MEM)
    wire [31:0] mem_alu_result;
    wire [31:0] mem_rs2;
    wire        mem_mem_read;
    wire        mem_mem_write;

    unified_mem mem (
        .clk(clk),
        .pc(pc),
        .instruction(instruction),     // fetched instruction (IF)
        .mem_read(mem_mem_read),       // MEM stage
        .mem_write(mem_mem_write),     // MEM stage
        .address(mem_alu_result),
        .write_data(mem_rs2),
        .read_data(mem_read_data)
    );

    // =========================
    // IF/ID pipeline register
    // =========================
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instr;
    wire        if_id_write;

    // Flush on taken branch or JAL/JALR (control hazard)
    wire flush_if_id;
    assign flush_if_id = ex_branch_taken | ex_jal | ex_jalr;

    IF_ID if_id_reg (
        .clk(clk),
        .reset(reset),
        .if_id_write(if_id_write),
        .flush(flush_if_id),
        .pc_in(pc),
        .instr_in(instruction),
        .pc_out(if_id_pc),
        .instr_out(if_id_instr)
    );

    // =========================
    // ID stage (Decode + Regfile + Control)
    // =========================
    wire [4:0]  rs1_addr;
    wire [4:0]  rs2_addr;
    wire [4:0]  rd_addr;
    wire [6:0]  opcode;
    wire [6:0]  funct7;
    wire [2:0]  funct3;
    wire [31:0] immediate;

    instr_decode id (
        .instruction(if_id_instr),
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

    // WB stage → Regfile
    wire        wb_reg_write;
    wire [4:0]  wb_rd;
    wire [31:0] wb_data;

    registers regs (
        .clk(clk),
        .we(wb_reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(wb_rd),
        .rd_data(wb_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Control signals (ID stage)
    wire [3:0] id_alu_op;
    wire       id_alu_src;
    wire       id_mem_to_reg;
    wire       id_reg_write;
    wire       id_mem_read;
    wire       id_mem_write;
    wire       id_branch;
    wire       id_jal;
    wire       id_jalr;

    control_unit cu (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(id_alu_op),
        .alu_src(id_alu_src),
        .mem_to_reg(id_mem_to_reg),
        .reg_write(id_reg_write),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .branch(id_branch),
        .jal(id_jal),
        .jalr(id_jalr)
    );
    
    // =========================
    // ID/EX pipeline register
    // =========================
    wire [31:0] ex_pc;
    wire [31:0] ex_rs1_data;
    wire [31:0] ex_rs2_data;
    wire [31:0] ex_imm;
    wire [4:0]  ex_rd;
    wire [2:0]  ex_funct3;
    wire [6:0]  ex_opcode;

    wire [3:0] ex_alu_op;
    wire [4:0] ex_rs1_addr;
    wire [4:0] ex_rs2_addr;
    wire       ex_alu_src;
    wire       ex_mem_read;
    wire       ex_mem_write;
    wire       ex_mem_to_reg;
    wire       ex_reg_write;
    wire       ex_branch;
    wire       ex_jal;
    wire       ex_jalr;

    // Branch/JAL/JALR flush for ID/EX
    wire flush_id_ex_branch = ex_branch_taken | ex_jal | ex_jalr;
    wire flush_id_ex_stall;
    wire flush_id_ex = flush_id_ex_branch | flush_id_ex_stall;

    ID_EX id_ex_reg (
        .clk(clk),
        .reset(reset),
        .flush(flush_id_ex),
        .pc_in(if_id_pc),
        .rs1_in(rs1_data),
        .rs2_in(rs2_data),
        .rs1_addr_in(rs1_addr),
        .rs2_addr_in(rs2_addr),
        .imm_in(immediate),
        .rd_in(rd_addr),
        .funct3_in(funct3),
        .opcode_in(opcode),
        .alu_op_in(id_alu_op),
        .alu_src_in(id_alu_src),
        .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write),
        .mem_to_reg_in(id_mem_to_reg),
        .reg_write_in(id_reg_write),
        .branch_in(id_branch),
        .jal_in(id_jal),
        .jalr_in(id_jalr),

        .pc_out(ex_pc),
        .rs1_out(ex_rs1_data),
        .rs2_out(ex_rs2_data),
        .rs1_addr_out(ex_rs1_addr),
        .rs2_addr_out(ex_rs2_addr),
        .imm_out(ex_imm),
        .rd_out(ex_rd),
        .funct3_out(ex_funct3),
        .opcode_out(ex_opcode),
        .alu_op_out(ex_alu_op),
        .alu_src_out(ex_alu_src),
        .mem_read_out(ex_mem_read),
        .mem_write_out(ex_mem_write),
        .mem_to_reg_out(ex_mem_to_reg),
        .reg_write_out(ex_reg_write),
        .branch_out(ex_branch),
        .jal_out(ex_jal),
        .jalr_out(ex_jalr)
    );
    
    // =========================
    // Stall (load-use hazard) unit
    // =========================
    stall_unit St(
        .id_ex_mem_read(ex_mem_read),
        .id_ex_rd(ex_rd),
        .if_id_rs1(rs1_addr),
        .if_id_rs2(rs2_addr),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .id_ex_flush(flush_id_ex_stall)
    );

    // =========================
    // EX stage (with forwarding)
    // =========================
    wire is_auipc_ex = (ex_opcode == 7'b0010111);
    wire is_lui_ex   = (ex_opcode == 7'b0110111);
    
    wire [1:0] forwardA, forwardB;

    // From EX/MEM and MEM/WB
    wire [4:0]  mem_rd;
    wire        mem_reg_write;
    wire [4:0]  wb_rd;
    wire        wb_reg_write;

    forward_unit fu(
        .rs1_in(ex_rs1_addr),
        .rs2_in(ex_rs2_addr),
        .ex_mem_rd(mem_rd),
        .ex_mem_reg_write(mem_reg_write),
        .mem_wb_rd(wb_rd),
        .mem_wb_reg_write(wb_reg_write),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );
    
    // Forwarded operands to ALU
    reg [31:0] alu_rs1;
    reg [31:0] alu_rs2;

    always @(*) begin
        // ALU input A forwarding
        case (forwardA)
            2'b00: alu_rs1 = ex_rs1_data;      // from ID/EX
            2'b10: alu_rs1 = mem_alu_result;   // from EX/MEM
            2'b01: alu_rs1 = wb_data;          // from MEM/WB
            default: alu_rs1 = ex_rs1_data;
        endcase
        
        // ALU input B forwarding
        case (forwardB)
            2'b00: alu_rs2 = ex_rs2_data;
            2'b10: alu_rs2 = mem_alu_result;
            2'b01: alu_rs2 = wb_data;
            default: alu_rs2 = ex_rs2_data;
        endcase
    end
        
    wire [31:0] ex_alu_a = is_auipc_ex ? ex_pc  : alu_rs1;
    wire [31:0] ex_alu_b = ex_alu_src  ? ex_imm : alu_rs2;

    wire [31:0] ex_alu_result;
    wire        ex_alu_zero;

    ALU alu_unit (
        .a(ex_alu_a),
        .b(ex_alu_b),
        .alu_op(ex_alu_op),
        .result(ex_alu_result),
        .zero(ex_alu_zero)
    );

    // Branch unit (EX) — must use forwarded operands!
    branch_unit bu (
        .branch(ex_branch),
        .rs1(alu_rs1),
        .rs2(alu_rs2),
        .funct3(ex_funct3),
        .branch_taken(ex_branch_taken)
    );

    // Branch / Jump targets (EX) — also use forwarded rs1 for JALR
    assign ex_branch_target = ex_pc + ex_imm;
    assign ex_jal_target    = ex_pc + ex_imm;
    assign ex_jalr_target   = (alu_rs1 + ex_imm) & 32'hffff_fffe;

    // PC+4 for JAL/JALR link writeback
    wire [31:0] ex_pc_plus4 = ex_pc + 32'd4;

    // =========================
    // EX/MEM pipeline register
    // =========================
    wire        mem_mem_to_reg;
    wire        mem_jal;
    wire        mem_jalr;
    wire        mem_is_lui;
    wire [31:0] mem_pc_plus4;
    wire [31:0] mem_imm;  // for LUI

    EX_MEM ex_mem_reg (
        .clk(clk),
        .reset(reset),

        .alu_result_in(ex_alu_result),
        .rs2_in(alu_rs2),          // use forwarded value!
        .rd_in(ex_rd),
        .mem_read_in(ex_mem_read),
        .mem_write_in(ex_mem_write),
        .mem_to_reg_in(ex_mem_to_reg),
        .reg_write_in(ex_reg_write),
        .jal_in(ex_jal),
        .jalr_in(ex_jalr),
        .is_lui_in(is_lui_ex),
        .pc_plus4_in(ex_pc_plus4),
        .imm_in(ex_imm),

        .alu_result_out(mem_alu_result),
        .rs2_out(mem_rs2),
        .rd_out(mem_rd),
        .mem_read_out(mem_mem_read),
        .mem_write_out(mem_mem_write),
        .mem_to_reg_out(mem_mem_to_reg),
        .reg_write_out(mem_reg_write),
        .jal_out(mem_jal),
        .jalr_out(mem_jalr),
        .is_lui_out(mem_is_lui),
        .pc_plus4_out(mem_pc_plus4),
        .imm_out(mem_imm)
    );

    // =========================
    // MEM/WB pipeline register
    // =========================
    wire [31:0] wb_mem_data;
    wire [31:0] wb_alu_result;
    wire [31:0] wb_pc_plus4;
    wire [31:0] wb_imm;
    wire        wb_mem_to_reg;
    wire        wb_jal;
    wire        wb_jalr;
    wire        wb_is_lui;

    MEM_WB mem_wb_reg (
        .clk(clk),
        .reset(reset),

        .mem_read_data_in(mem_read_data),
        .alu_result_in(mem_alu_result),
        .rd_in(mem_rd),
        .mem_to_reg_in(mem_mem_to_reg),
        .reg_write_in(mem_reg_write),
        .jal_in(mem_jal),
        .jalr_in(mem_jalr),
        .is_lui_in(mem_is_lui),
        .pc_plus4_in(mem_pc_plus4),
        .imm_in(mem_imm),

        .mem_read_data_out(wb_mem_data),
        .alu_result_out(wb_alu_result),
        .rd_out(wb_rd),
        .mem_to_reg_out(wb_mem_to_reg),
        .reg_write_out(wb_reg_write),
        .jal_out(wb_jal),
        .jalr_out(wb_jalr),
        .is_lui_out(wb_is_lui),
        .pc_plus4_out(wb_pc_plus4),
        .imm_out(wb_imm)
    );

    // =========================
    // WB stage
    // =========================
    assign wb_data =
        (wb_reg_write && (wb_jal || wb_jalr)) ? wb_pc_plus4 :
        (wb_reg_write && wb_is_lui)           ? wb_imm      :
        (wb_reg_write && wb_mem_to_reg)       ? wb_mem_data :
                                               wb_alu_result;

endmodule
