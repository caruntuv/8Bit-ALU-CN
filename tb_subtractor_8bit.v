`timescale 1ns/1ps
module tb_subtractor_8bit;
    reg  [7:0] A, B;
    reg        enable;
    wire [7:0] Diff;
    wire       Bout;

    subtractor_8bit DUT (.A(A), .B(B), .enable(enable), .Diff(Diff), .Bout(Bout));

    task check;
        input [7:0]  exp_diff;
        input        exp_bout;
        input [63:0] label;
        begin
            #10;
            $display("[%0s] %0d - %0d => Diff=%0d Bout=%0b | exp=%0d/%0b | %0s",
                label, A, B, Diff, Bout, exp_diff, exp_bout,
                (Diff == exp_diff && Bout == exp_bout) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        $display("=== Subtractor 8-bit Testbench ===");
        enable = 1;
        A=8'd50;  B=8'd20;  check(8'd30,  0, "BASIC  ");
        A=8'd10;  B=8'd20;  check(8'd246, 1, "BORROW ");
        A=8'd255; B=8'd255; check(8'd0,   0, "EQUAL  ");
        A=8'd0;   B=8'd1;   check(8'd255, 1, "ZERO   ");
        $display("=== Done ===");
        $finish;
    end
endmodule
