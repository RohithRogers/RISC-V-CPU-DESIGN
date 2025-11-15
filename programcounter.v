module programcounter(
    input wire clk,
    input wire reset,

    input wire branch_taken,
    input wire [31:0] branch_target,

    input wire jal, // Jump and Link pc = pc + immediate
    input wire jalr, // Jump and Link Register pc = rs1 + immediate
    input wire [31:0] jal_target,
    input wire [31:0] jalr_target,

    output reg [31:0] pc
);

reg [31:0] pc_next;

always @(*) begin
    // PC selection logic
    if (jalr)
        pc_next = jalr_target;
    else if (jal)
        pc_next = jal_target;
    else if (branch_taken)
        pc_next = branch_target;
    else
        pc_next = pc + 32'd4;
end

always @(posedge clk or posedge reset) begin
    if (reset)
        pc <= 32'd0;
    else
        pc <= pc_next;
end

endmodule
