`timescale 1ns/1ps
module tb_adder_8bit;
    reg  [7:0] A, B;
    reg        Cin, enable;
    wire [7:0] Sum;
    wire       Cout;

    adder_8bit DUT (.A(A), .B(B), .Cin(Cin), .enable(enable), .Sum(Sum), .Cout(Cout));

    task check;
        input [7:0]  exp_sum;
        input        exp_cout;
        input [63:0] label;
        begin
            #10;
            $display("[%0s] %0d + %0d + cin=%0b => Sum=%0d Cout=%0b | exp=%0d/%0b | %0s",
                label, A, B, Cin, Sum, Cout, exp_sum, exp_cout,
                (Sum == exp_sum && Cout == exp_cout) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        $display("=== Adder 8-bit Testbench ===");
        enable = 1;
        A=8'd10;  B=8'd20;  Cin=0; check(8'd30,  0, "BASIC   ");
        A=8'd100; B=8'd200; Cin=0; check(8'd44,  1, "OVERFLOW");
        A=8'd255; B=8'd1;   Cin=0; check(8'd0,   1, "WRAP    ");
        A=8'd127; B=8'd127; Cin=1; check(8'd255, 0, "CIN     ");
        enable=0; A=8'd5; B=8'd5; Cin=0; #10;
        $display("[ENABLE=0] Sum=%b (expect Z/X)", Sum);
        $display("=== Done ===");
        $finish;
    end
endmodule
