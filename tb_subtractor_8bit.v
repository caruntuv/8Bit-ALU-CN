`timescale 1ns/1ps
//subtractor test bench
module tb_subtractor_8bit;
    reg  [7:0] A, B;
    reg        enable;
    wire [7:0] Diff;
    wire       Bout;
//initiate dut(device under test)

    subtractor_8bit DUT (.A(A), .B(B), .enable(enable), .Diff(Diff), .Bout(Bout));

    //tast applies delay and checks result vs expected result
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
//main test sequence
    initial begin
        $display("=== Subtractor 8-bit Testbench ===");
        //enable module
        enable = 1;
        //normal case
        A=8'd50;  B=8'd20;  check(8'd30,  0, "BASIC  ");
        //restult negative->borrow expected
        A=8'd10;  B=8'd20;  check(8'd246, 1, "BORROW ");
        //same numbers=>result 0
        A=8'd255; B=8'd255; check(8'd0,   0, "EQUAL  ");
        //underflow case
        A=8'd0;   B=8'd1;   check(8'd255, 1, "ZERO   ");
        $display("=== Done ===");
        $finish;
    end
endmodule