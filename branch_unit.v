module branch_unit(
    input wire branch,
    input wire [31:0] rs1,
    input wire [31:0] rs2,
    input wire [2:0] funct3,
    output reg branch_taken
);
always @(*) begin
    if (!branch) begin
        branch_taken = 0;
    end 
    else begin
        case (funct3)
            3'b000: branch_taken = (rs1 == rs2);          // BEQ
            3'b001: branch_taken = (rs1 != rs2);          // BNE
            3'b100: branch_taken = ($signed(rs1) < $signed(rs2)); // BLT
            3'b101: branch_taken = ($signed(rs1) >= $signed(rs2)); // BGE
            3'b110: branch_taken = (rs1 < rs2);           // BLTU
            3'b111: branch_taken = (rs1 >= rs2);          // BGEU
            default: branch_taken = 0;
        endcase
    end
end

endmodule