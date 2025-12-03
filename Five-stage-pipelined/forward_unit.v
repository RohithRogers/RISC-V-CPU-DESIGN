module forward_unit(
    input  wire [4:0] rs1_in,
    input  wire [4:0] rs2_in,

    input  wire [4:0] ex_mem_rd,
    input  wire       ex_mem_reg_write,

    input  wire [4:0] mem_wb_rd,
    input  wire       mem_wb_reg_write,

    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);
    always @(*) begin
        // default: no forwarding
        forwardA = 2'b00;
        forwardB = 2'b00;

        // EX/MEM hazard
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == rs1_in))
            forwardA = 2'b10;
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == rs2_in))
            forwardB = 2'b10;

        // MEM/WB hazard (only if not already taken from EX/MEM)
        if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == rs1_in) && (forwardA == 2'b00))
            forwardA = 2'b01;
        if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == rs2_in) && (forwardB == 2'b00))
            forwardB = 2'b01;
    end
endmodule

