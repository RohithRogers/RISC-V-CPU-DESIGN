`timescale 1ns/1ps

module tb_core_sum;

    reg clk;
    reg reset;

    wire [31:0] pc_out;

    // Instantiate your core
    core uut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out)
    );

    // Generate clock (10ns period)
    always #5 clk = ~clk;

    integer cycle;

    initial begin
        $display("=== RV32I CORE: SUM OF FIRST 10 NATURAL NUMBERS ===");
        
        clk = 0;
        reset = 1;

        // Enable wave dump
        $dumpfile("core.vcd");
        $dumpvars(0, tb_core_sum);

        // Hold reset for a few cycles
        #20;
        reset = 0;

        // Run for 50 cycles
        for (cycle = 0; cycle < 50; cycle = cycle + 1) begin
            @(posedge clk);

            // Print PC + registers x10(sum), x11(i), x12(limit)
            $display("Cycle %0d | PC=%h | x10(sum)=%h | x11(i)=%h | x12(limit)=%h",
                cycle,
                pc_out,
                uut.regs.regfile[10],
                uut.regs.regfile[11],
                uut.regs.regfile[12]
            );
        end

        $display("=== SIMULATION COMPLETE ===");
        $finish;
    end

endmodule
