module stall_unit(
    input  wire        id_ex_mem_read,
    input  wire [4:0]  id_ex_rd,

    input  wire [4:0]  if_id_rs1,
    input  wire [4:0]  if_id_rs2,

    output reg         pc_write,
    output reg         if_id_write,
    output reg         id_ex_flush
);

    always @(*) begin
        // --------- LOAD-USE HAZARD DETECTION ---------
        if ( id_ex_mem_read &&
            ( (if_id_rs1 == id_ex_rd) || (if_id_rs2 == id_ex_rd) ) &&
              (id_ex_rd != 5'd0) ) 
        begin
            // STALL
            pc_write    = 1'b0;   // freeze PC
            if_id_write = 1'b0;   // freeze IF/ID
            id_ex_flush = 1'b1;   // insert bubble into EX
        end
        else begin
            // NORMAL FLOW
            pc_write    = 1'b1;
            if_id_write = 1'b1;
            id_ex_flush = 1'b0;
        end
    end

endmodule
