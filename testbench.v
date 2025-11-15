`timescale 1ns/1ps

module tb_pc_imem;

    reg clk;
    reg reset;

    // JAL / JALR / Branch inputs
    reg jal, jalr, branch_taken;
    reg [31:0] jal_target, jalr_target, branch_target;

    wire [31:0] pc;
    wire [31:0] instruction;

    // Instantiate Program Counter
    programcounter uut_pc (
        .clk(clk),
        .reset(reset),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .jal(jal),
        .jalr(jalr),
        .jal_target(jal_target),
        .jalr_target(jalr_target),
        .pc(pc)
    );

    // Instantiate Instruction Memory
    instr_mem uut_imem (
        .pc(pc),
        .instruction(instruction)
    );

    // Clock generation
    always #5 clk = ~clk;   // 10ns period → 100MHz clock

    initial begin
        $dumpvars(0, tb_pc_imem);
        $dumpfile("tb_pc_imem.vcd");
        $display("Starting PC + Instruction Memory Testbench...");
        
        // Initialize
        clk = 0;
        reset = 1;
        jal = 0;
        jalr = 0;
        branch_taken = 0;
        jal_target = 0;
        jalr_target = 0;
        branch_target = 0;

        // Release reset
        #20 reset = 0;

        // Let PC run normally for a few cycles
        repeat(5) begin
            @(posedge clk);
            $display("Cycle %0d | PC = %h | INSTR = %h", 
                      $time, pc, instruction);
        end

        // Test JAL
        @(posedge clk);
        jal = 1;
        jal_target = 32'h00000040;   // jump to address 0x40
        @(posedge clk);
        jal = 0;

        $display("After JAL | PC = %h | INSTR = %h", pc, instruction);

        // Run more cycles after jump
        repeat(3) begin
            @(posedge clk);
            $display("Cycle %0d | PC = %h | INSTR = %h", 
                      $time, pc, instruction);
        end

        // Test JALR
        @(posedge clk);
        jalr = 1;
        jalr_target = 32'h00000080; // jump to 0x80
        @(posedge clk);
        jalr = 0;

        $display("After JALR | PC = %h | INSTR = %h", pc, instruction);

        // Run more
        repeat(3) begin
            @(posedge clk);
            $display("Cycle %0d | PC = %h | INSTR = %h", 
                      $time, pc, instruction);
        end

        $display("Testbench Completed.");
        $finish;
    end

endmodule
