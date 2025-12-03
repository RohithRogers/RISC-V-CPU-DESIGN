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

    // These come from EX stage (control flow)
    wire        ex_branch_taken;
    wire [31:0] ex_branch_target;
    wire [31:0] ex_jal_target, ex_jalr_target;

    // Stall control
    wire pc_write;

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

    // MEM stage addr/data/control (from EX/MEM)
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

    // We'll use a registered branch_taken for stable flushing
    reg ex_branch_taken_r;

    always @(posedge clk) begin
        if (reset)
            ex_branch_taken_r <= 1'b0;
        else
            ex_branch_taken_r <= ex_branch_taken;
    end

    // IF/ID flush on taken branch or JAL/JALR (from EX stage)
    wire flush_if_id;
    // ex_jal/ex_jalr will be defined later (from ID/EX)
    wire ex_jal;
    wire ex_jalr;

    assign flush_if_id = ex_branch_taken_r | ex_jal | ex_jalr;

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
    // ex_jal, ex_jalr already declared as wires above

    // Load-use stall hazard flush for ID/EX
    wire flush_id_ex_stall;

    // Branch/JAL/JALR flush for ID/EX
    wire flush_id_ex_branch;
    assign flush_id_ex_branch = ex_branch_taken_r | ex_jal | ex_jalr;

    wire flush_id_ex = flush_id_ex_stall;

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
    // Load-use stall unit (simple inline logic)
    // =========================
    wire load_use_hazard;
    assign load_use_hazard =
        ex_mem_read &&
        (ex_rd != 5'd0) &&
        ((ex_rd == rs1_addr) || (ex_rd == rs2_addr));

    assign pc_write        = ~load_use_hazard;
    assign if_id_write     = ~load_use_hazard;
    assign flush_id_ex_stall = load_use_hazard;

    // =========================
    // EX stage (with integrated forwarding)
    // =========================
    wire is_auipc_ex = (ex_opcode == 7'b0010111);
    wire is_lui_ex   = (ex_opcode == 7'b0110111);
    
    // From EX/MEM and MEM/WB for forwarding
    wire [4:0]  mem_rd;
    wire        mem_reg_write;
    wire        wb_mem_to_reg;
    wire        wb_jal;
    wire        wb_jalr;
    wire        wb_is_lui;

    // Forwarded operands to ALU
    reg [31:0] alu_rs1;
    reg [31:0] alu_rs2;

    always @(*) begin
        // Default: from ID/EX
        alu_rs1 = ex_rs1_data;
        alu_rs2 = ex_rs2_data;

        // Forward for rs1
        if (mem_reg_write && (mem_rd != 5'd0) && (mem_rd == ex_rs1_addr))
            alu_rs1 = mem_alu_result;
        else if (wb_reg_write && (wb_rd != 5'd0) && (wb_rd == ex_rs1_addr))
            alu_rs1 = wb_data;

        // Forward for rs2
        if (mem_reg_write && (mem_rd != 5'd0) && (mem_rd == ex_rs2_addr))
            alu_rs2 = mem_alu_result;
        else if (wb_reg_write && (wb_rd != 5'd0) && (wb_rd == ex_rs2_addr))
            alu_rs2 = wb_data;
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

    // Branch unit (EX) — uses forwarded operands
    branch_unit bu (
        .branch(ex_branch),
        .rs1(alu_rs1),
        .rs2(alu_rs2),
        .funct3(ex_funct3),
        .branch_taken(ex_branch_taken)
    );
    
    // Branch / Jump targets (EX) — use EX PC and forwarded rs1
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


// =========================
// Pipeline register modules
// =========================

module IF_ID (
    input  wire        clk,
    input  wire        reset,
    input  wire        flush,
    input  wire        if_id_write,
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out
);
    always @(posedge clk) begin
        if (reset || flush) begin
            pc_out    <= 32'd0;
            // NOP = ADDI x0,x0,0 = 0x00000013
            instr_out <= 32'h00000013;
        end
        else if (if_id_write) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
    end
endmodule


module ID_EX (
    input  wire        clk,
    input  wire        reset,
    input  wire        flush,

    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_in,
    input  wire [31:0] rs2_in,
    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rd_in,
    input  wire [2:0]  funct3_in,
    input  wire [6:0]  opcode_in,

    input  wire [3:0]  alu_op_in,
    input  wire        alu_src_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        reg_write_in,
    input  wire        branch_in,
    input  wire        jal_in,
    input  wire        jalr_in,

    output reg  [31:0] pc_out,
    output reg  [31:0] rs1_out,
    output reg  [31:0] rs2_out,
    output reg  [4:0]  rs1_addr_out,
    output reg  [4:0]  rs2_addr_out,
    output reg  [31:0] imm_out,
    output reg  [4:0]  rd_out,
    output reg  [2:0]  funct3_out,
    output reg  [6:0]  opcode_out,

    output reg  [3:0]  alu_op_out,
    output reg         alu_src_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         mem_to_reg_out,
    output reg         reg_write_out,
    output reg         branch_out,
    output reg         jal_out,
    output reg         jalr_out
);
    always @(posedge clk) begin
        if (reset) begin
            pc_out         <= 32'd0;
            rs1_out        <= 32'd0;
            rs2_out        <= 32'd0;
            rs1_addr_out   <= 5'd0;
            rs2_addr_out   <= 5'd0;
            imm_out        <= 32'd0;
            rd_out         <= 5'd0;
            funct3_out     <= 3'd0;
            opcode_out     <= 7'd0;

            alu_op_out     <= 4'd0;
            alu_src_out    <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            reg_write_out  <= 1'b0;
            branch_out     <= 1'b0;
            jal_out        <= 1'b0;
            jalr_out       <= 1'b0;
        end else begin
            // Data path always updates
            pc_out       <= pc_in;
            rs1_out      <= rs1_in;
            rs2_out      <= rs2_in;
            rs1_addr_out <= rs1_addr_in;
            rs2_addr_out <= rs2_addr_in;
            imm_out      <= imm_in;
            rd_out       <= rd_in;
            funct3_out   <= funct3_in;
            opcode_out   <= opcode_in;

            if (flush) begin
                // On flush: turn this into a NOP by clearing only control
                alu_op_out     <= 4'd0;
                alu_src_out    <= 1'b0;
                mem_read_out   <= 1'b0;
                mem_write_out  <= 1'b0;
                mem_to_reg_out <= 1'b0;
                reg_write_out  <= 1'b0;
                branch_out     <= 1'b0;
                jal_out        <= 1'b0;
                jalr_out       <= 1'b0;
            end else begin
                alu_op_out     <= alu_op_in;
                alu_src_out    <= alu_src_in;
                mem_read_out   <= mem_read_in;
                mem_write_out  <= mem_write_in;
                mem_to_reg_out <= mem_to_reg_in;
                reg_write_out  <= reg_write_in;
                branch_out     <= branch_in;
                jal_out        <= jal_in;
                jalr_out       <= jalr_in;
            end
        end
    end
endmodule


module EX_MEM (
    input  wire        clk,
    input  wire        reset,

    input  wire [31:0] alu_result_in,
    input  wire [31:0] rs2_in,
    input  wire [4:0]  rd_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        reg_write_in,
    input  wire        jal_in,
    input  wire        jalr_in,
    input  wire        is_lui_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] imm_in,

    output reg  [31:0] alu_result_out,
    output reg  [31:0] rs2_out,
    output reg  [4:0]  rd_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         mem_to_reg_out,
    output reg         reg_write_out,
    output reg         jal_out,
    output reg         jalr_out,
    output reg         is_lui_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] imm_out
);
    always @(posedge clk) begin
        if (reset) begin
            alu_result_out <= 32'd0;
            rs2_out        <= 32'd0;
            rd_out         <= 5'd0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            reg_write_out  <= 1'b0;
            jal_out        <= 1'b0;
            jalr_out       <= 1'b0;
            is_lui_out     <= 1'b0;
            pc_plus4_out   <= 32'd0;
            imm_out        <= 32'd0;
        end else begin
            alu_result_out <= alu_result_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            reg_write_out  <= reg_write_in;
            jal_out        <= jal_in;
            jalr_out       <= jalr_in;
            is_lui_out     <= is_lui_in;
            pc_plus4_out   <= pc_plus4_in;
            imm_out        <= imm_in;
        end
    end
endmodule


module MEM_WB (
    input  wire        clk,
    input  wire        reset,

    input  wire [31:0] mem_read_data_in,
    input  wire [31:0] alu_result_in,
    input  wire [4:0]  rd_in,
    input  wire        mem_to_reg_in,
    input  wire        reg_write_in,
    input  wire        jal_in,
    input  wire        jalr_in,
    input  wire        is_lui_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] imm_in,

    output reg  [31:0] mem_read_data_out,
    output reg  [31:0] alu_result_out,
    output reg  [4:0]  rd_out,
    output reg         mem_to_reg_out,
    output reg         reg_write_out,
    output reg         jal_out,
    output reg         jalr_out,
    output reg         is_lui_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] imm_out
);
    always @(posedge clk) begin
        if (reset) begin
            mem_read_data_out <= 32'd0;
            alu_result_out    <= 32'd0;
            rd_out            <= 5'd0;
            mem_to_reg_out    <= 1'b0;
            reg_write_out     <= 1'b0;
            jal_out           <= 1'b0;
            jalr_out          <= 1'b0;
            is_lui_out        <= 1'b0;
            pc_plus4_out      <= 32'd0;
            imm_out           <= 32'd0;
        end else begin
            mem_read_data_out <= mem_read_data_in;
            alu_result_out    <= alu_result_in;
            rd_out            <= rd_in;
            mem_to_reg_out    <= mem_to_reg_in;
            reg_write_out     <= reg_write_in;
            jal_out           <= jal_in;
            jalr_out          <= jalr_in;
            is_lui_out        <= is_lui_in;
            pc_plus4_out      <= pc_plus4_in;
            imm_out           <= imm_in;
        end
    end
endmodule
