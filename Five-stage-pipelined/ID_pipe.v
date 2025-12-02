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
        if (reset || flush) begin
            pc_out         <= 32'd0;
            rs1_out        <= 32'd0;
            rs2_out        <= 32'd0;
            imm_out        <= 32'd0;
            rs1_addr_out   <= 5'd0;
            rs2_addr_out   <= 5'd0;
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
            pc_out         <= pc_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rs1_addr_out   <= rs1_addr_in;
            rs2_addr_out   <= rs2_addr_in;
            imm_out        <= imm_in;
            rd_out         <= rd_in;
            funct3_out     <= funct3_in;
            opcode_out     <= opcode_in;

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
endmodule

