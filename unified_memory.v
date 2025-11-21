module unified_mem (
    input  wire        clk,

    // Instruction fetch
    input  wire [31:0] pc,
    output reg  [31:0] instruction,

    // Data port
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);

    reg [7:0] memory [0:4095]; // 64KB unified memory

    // Load program + data into same array
    initial begin
        $readmemh("program.hex", memory);
    end

    // Instruction fetch (asynchronous)
    always @(*) begin
        instruction = { 
            memory[pc + 3],
            memory[pc + 2],
            memory[pc + 1],
            memory[pc + 0]
        };
    end

    // Data reads (asynchronous or sync — here async)
    always @(*) begin
        if (mem_read) begin
            read_data = {
                memory[address + 3],
                memory[address + 2],
                memory[address + 1],
                memory[address + 0]
            };
        end
    end

    // Data write (must be synchronous)
    always @(posedge clk) begin
        if (mem_write) begin
            memory[address + 0] <= write_data[7:0];
            memory[address + 1] <= write_data[15:8];
            memory[address + 2] <= write_data[23:16];
            memory[address + 3] <= write_data[31:24];
        end
    end

endmodule
