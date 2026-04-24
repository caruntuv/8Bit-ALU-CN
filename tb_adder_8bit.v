`timescale 1ns/1ps
module tb_adder_8bit;
    reg  [7:0] A, B;
    reg        Cin, enable;
    wire [7:0] Sum;
    wire       Cout;

    adder_8bit DUT (.A(A), .B(B), .Cin(Cin), .enable(enable), .Sum(Sum), .Cout(Cout));

    // waveform
    initial begin
        $dumpfile("adder.vcd");      // fisier waveform
        $dumpvars(0, tb_adder_8bit); // dump toate semnalele
    end

    task check;
        input [7:0]   exp_sum;
        input         exp_cout;
        input [255:0] label;
        begin
            #10;
            $display("%0s", label);
            $display("A=%0d B=%0d Cin=%0b", A, B, Cin);
            $display("Sum=%0d Cout=%0b", Sum, Cout);
            $display("%0s\n", (Sum == exp_sum && Cout == exp_cout) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        $display("Testare Modul Adunare\n");

        enable = 1;

        A=8'd10; B=8'd20; Cin=0;
        check(8'd30, 0, "1. calcul normal");

        A=8'd255; B=8'd1; Cin=0;
        check(8'd0, 1, "2. overflow: 255 + 1");

        A=8'd127; B=8'd127; Cin=1;
        check(8'd255, 0, "3. calcul cu cin");

        $display("Final testare modul adunare");
        $finish;
    end
endmodule