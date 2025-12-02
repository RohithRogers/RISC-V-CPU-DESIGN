`timescale 1ns/1ps

module tb_debug;
    reg clk;
    reg reset;
    wire [31:0] pc_out;

    // Instantiate DUT (core)
    core uut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out)
    );

    // clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    task print_word(input integer addr);
        reg [31:0] word;
    begin
        word = { uut.mem.memory[addr+3],
                 uut.mem.memory[addr+2],
                 uut.mem.memory[addr+1],
                 uut.mem.memory[addr+0] };

        $display("MEM[0x%04h] = %08h", addr, word);
    end
    endtask
    
    task dump_range(input integer start, input integer count);
        integer i;
    begin
        $display("\n--- MEMORY DUMP: 0x%04h to 0x%04h ---",
                 start, start + count*4);

        for (i = 0; i < count; i = i + 1)
            print_word(start + i*4);

        $display("--- END MEMORY DUMP ---\n");
    end
    endtask


    initial begin
        $dumpfile("debug.vcd");
        $dumpvars(0, tb_debug);

        $display("\n=== DEBUG TB START ===");
        reset = 1;
        repeat (4) @(posedge clk);
        reset = 0;
        repeat (1) @(posedge clk);
        dump_range(32'h00000024, 5);
        $monitor("Time : %t x5: %d  x6 = %d x7 = %d x10 = %d",$time,uut.regs.regfile[5],uut.regs.regfile[6],uut.regs.regfile[7],uut.regs.regfile[10]);
        repeat(600) @(posedge clk);
        $finish();
           
    end
    

endmodule
