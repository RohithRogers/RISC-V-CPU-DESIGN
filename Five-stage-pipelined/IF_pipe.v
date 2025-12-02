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
        else begin
            pc_out    <= pc_out;
            instr_out <= instr_out;
        end
    end
endmodule