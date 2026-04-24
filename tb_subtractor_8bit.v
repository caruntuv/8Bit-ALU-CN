`timescale 1ns/1ps
module tb_subtractor_8bit;

    reg  [7:0] A, B;
    reg        enable;
    wire [7:0] Diff;
    wire       Bout;

    subtractor_8bit DUT (
        .A(A), .B(B), .enable(enable),
        .Diff(Diff), .Bout(Bout)
    );

    // waveform
    initial begin
        $dumpfile("subtractor.vcd");
        $dumpvars(0, tb_subtractor_8bit);
    end

    // verificare
    task check;
        input [7:0]   exp_diff;
        input         exp_bout;
        input [255:0] label;
        begin
            #10;
            $display("%0s", label);
            $display("A=%0d B=%0d", A, B);
            $display("Diff=%0d Bout=%0b", Diff, Bout);
            $display("%0s\n", (Diff == exp_diff && Bout == exp_bout) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        $display("Testare Modul Scadere\n");

        enable = 1;

        // 1. calcul normal
        A = 8'd20; B = 8'd10;
        check(8'd10, 0, "1. calcul normal: 20 - 10");

        // 2. cu imprumut (borrow)
        A = 8'd10; B = 8'd20;
        check(8'd246, 1, "2. situatie borrow: 10 - 20");

        $display("Final testare modul scadere");
        $finish;
    end

endmodule