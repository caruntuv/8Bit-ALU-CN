`timescale 1ns/1ps
module tb_restoring_divider;

    reg clk, rst, start;
    reg [7:0] Dividend, Divisor;
    wire [7:0] Quotient, Remainder;
    wire done, div_by_zero;

    restoring_divider DUT (
        .clk(clk), .rst(rst), .start(start), .enable(1'b1),
        .Dividend(Dividend), .Divisor(Divisor),
        .Quotient(Quotient), .Remainder(Remainder),
        .done(done), .div_by_zero(div_by_zero)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("divider.vcd");
        $dumpvars(0, tb_restoring_divider);
    end

    task check;
        input [7:0] exp_q;
        input [7:0] exp_r;
        input       exp_dbz;
        input [255:0] label;
        begin
            wait(done);
            #5;
            $display("%0s", label);
            $display("Dividend=%0d Divisor=%0d", Dividend, Divisor);
            $display("Quotient=%0d Remainder=%0d Div_by_zero=%0b", Quotient, Remainder, div_by_zero);
            $display("%0s\n", (Quotient == exp_q && Remainder == exp_r && div_by_zero == exp_dbz) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        $display("Testare Modul Impartire\n");

        clk = 0; rst = 1; start = 0;
        #10 rst = 0;

        Dividend = 8'd20; Divisor = 8'd4;
        start = 1; #10 start = 0;
        check(8'd5, 8'd0, 0, "1. impartire exacta: 20 / 4");

        Dividend = 8'd22; Divisor = 8'd5;
        start = 1; #10 start = 0;
        check(8'd4, 8'd2, 0, "2. impartire cu rest: 22 / 5");

        Dividend = 8'd10; Divisor = 8'd0;
        start = 1; #10 start = 0;
        check(8'd0, 8'd0, 1, "3. situatie speciala: impartire la zero");

        $display("Final testare modul impartire");
        $finish;
    end
endmodule