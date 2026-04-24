`timescale 1ns/1ps
//restoring divider 
module tb_restoring_divider;
    reg        clk, rst, start, enable;
    reg  [7:0] Dividend, Divisor;
    wire [7:0] Quotient, Remainder;
    wire       done, div_by_zero;

    restoring_divider DUT (
        .clk(clk), .rst(rst), .start(start), .enable(enable),
        .Dividend(Dividend), .Divisor(Divisor),
        .Quotient(Quotient), .Remainder(Remainder),
        .done(done), .div_by_zero(div_by_zero)
    );
//clock(10ns)
    always #5 clk = ~clk;
//helper task for running one div
//start->wait done->check result(check is for linux cmd panel)
//didn t delete the check part->no reason to.
    task check;
        input [7:0] dd, dv, exp_q, exp_r;
        begin
            Dividend=dd; Divisor=dv; start=1; #10; start=0;
            wait(done); #10;
            $display("[DIV] %0d / %0d => Q=%0d R=%0d | exp Q=%0d R=%0d | %0s",
                dd, dv, Quotient, Remainder, exp_q, exp_r,
                (Quotient==exp_q && Remainder==exp_r) ? "PASS" : "FAIL");
        end
    endtask
//test 
    initial begin
      //init signals and reset
        clk=0; rst=1; start=0; enable=1;
        #15; rst=0;
        $display("=== Restoring Divider Testbench ===");
        //normal divisions
        check(8'd20,  8'd4,  8'd5,  8'd0);
        check(8'd25,  8'd4,  8'd6,  8'd1);
        check(8'd100, 8'd7,  8'd14, 8'd2);
        check(8'd0,   8'd5,  8'd0,  8'd0);
        //division by 0 case
        Dividend=8'd10; Divisor=8'd0; start=1; #10; start=0;
        wait(done); #10;
        $display("[DIV-BY-ZERO] flag=%0b | exp=1 | %0s",
            div_by_zero, div_by_zero ? "PASS" : "FAIL");
        $display("=== Done ===");
        $finish;
    end
endmodule