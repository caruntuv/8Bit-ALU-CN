`timescale 1ns/1ps
module tb_alu_8bit;
    reg        clk, rst, start;
    reg  [1:0] op;
    reg  [7:0] A_in, B_in;
    wire [15:0] OUTBUS;
    wire        alu_done;

    alu_8bit DUT (
        .clk(clk), .rst(rst), .op(op), .start(start),
        .A_in(A_in), .B_in(B_in),
        .OUTBUS(OUTBUS), .alu_done(alu_done)
    );

    always #5 clk = ~clk;

    task check;
        input [1:0]  operation;
        input [7:0]  a, b;
        input [15:0] expected;
        input [63:0] label;
        begin
            op=operation; A_in=a; B_in=b;
            start=1; #10; start=0;
            wait(alu_done); #10;
            $display("[%0s] %0d op%0b %0d => %0d | exp=%0d | %0s",
                label, a, operation, b, OUTBUS, expected,
                (OUTBUS == expected) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        clk=0; rst=1; start=0; op=0; A_in=0; B_in=0;
        #15; rst=0;
        $display("=== ALU 8-bit Integration Testbench ===");
        check(2'b00, 8'd30,  8'd12,  16'd42,          "ADD    ");
        check(2'b00, 8'd200, 8'd100, 16'd300,          "ADD_OVF");
        check(2'b01, 8'd50,  8'd20,  16'd30,           "SUB    ");
        check(2'b01, 8'd10,  8'd20,  {8'd1, 8'd246},   "SUB_BRW");
        check(2'b10, 8'd6,   8'd7,   16'd42,           "MUL    ");
        check(2'b10, 8'd15,  8'd15,  16'd225,          "MUL_15 ");
        check(2'b11, 8'd42,  8'd6,   {8'd7, 8'd0},     "DIV    ");
        check(2'b11, 8'd100, 8'd7,   {8'd14, 8'd2},    "DIV_REM");
        $display("=== Done ===");
        $finish;
    end
endmodule
