module instr_mem(
    input wire [31:0] pc,
    output reg [31:0] instruction
);

    reg [31:0] memory [0:1023];

    initial begin
        $readmemh("instructions.hex", memory);
    end

    always @(*) begin
        instruction = memory[pc[11:2]];  // word address
    end

endmodule
