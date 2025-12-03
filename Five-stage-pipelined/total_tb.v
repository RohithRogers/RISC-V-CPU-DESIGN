`timescale 1ns/1ps

module tb_core_branch;

    reg clk;
    reg reset;
    wire [31:0] pc_out;

    // DUT
    core uut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out)
    );

    // Clock: 10ns period
    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;

        $dumpfile("branch_test.vcd");
        $dumpvars(0, tb_core_branch);

        #20;
        reset = 0;

        // Let it run for some cycles
        repeat (80) @(posedge clk);

        $display("\n==== FINAL REGISTER VALUES ====");
        $display("x3 = %0d", uut.regs.regfile[3]);
        $display("x4 = %0d", uut.regs.regfile[4]);
        $display("x5 = %0d", uut.regs.regfile[5]);
        $display("x6 = %0d", uut.regs.regfile[6]);
        $display("x7 = %0d", uut.regs.regfile[7]);
        $display("x8 = %0d", uut.regs.regfile[8]);
        $display("x9 = %0d", uut.regs.regfile[9]);
        $display("x10 = %0d", uut.regs.regfile[10]);
        

        $finish;
    end

    // Cycle-by-cycle monitor
    always @(posedge clk) begin
        if (!reset) begin
            $display("T=%0t | PC=%08h | x9=%0d x10=%0d x11=%0d x12=%0d",
                     $time,
                     pc_out,
                     uut.regs.regfile[9],
                     uut.regs.regfile[10],
                     uut.regs.regfile[11],
                     uut.regs.regfile[12],
                     );
        end
    end

endmodule

