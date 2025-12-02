module forward_unit(
    input  [4:0] rs1_in,
    input  [4:0] rs2_in,

    input  [4:0] ex_mem_rd,
    input        ex_mem_reg_write,

    input  [4:0] mem_wb_rd,
    input        mem_wb_reg_write,

    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);

    always @(*) begin
        // -------------------------
        // Default: no forwarding
        // -------------------------
        forwardA = 2'b00;
        forwardB = 2'b00;

        // -------------------------
        // EX/MEM → EX (highest priority)
        // -------------------------
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == rs1_in))
            forwardA = 2'b10;

        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == rs2_in))
            forwardB = 2'b10;

        // -------------------------
        // MEM/WB → EX (lower priority)
        // -------------------------
        if (mem_wb_reg_write && (mem_wb_rd != 0) &&
           !(ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == rs1_in)) &&
            (mem_wb_rd == rs1_in))
            forwardA = 2'b01;

        if (mem_wb_reg_write && (mem_wb_rd != 0) &&
           !(ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == rs2_in)) &&
            (mem_wb_rd == rs2_in))
            forwardB = 2'b01;
    end

endmodule
