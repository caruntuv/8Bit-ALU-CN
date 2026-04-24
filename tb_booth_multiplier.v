`timescale 1ns/1ps
module tb_booth_multiplier;

    reg clk, rst, start;
    reg [7:0] M, Q;
    wire [15:0] Product;
    wire done;

    booth_multiplier DUT (
        .clk(clk), .rst(rst), .start(start), .enable(1'b1),
        .M(M), .Q(Q),
        .Product(Product), .done(done)
    );

    // clock
    always #5 clk = ~clk;

    // waveform
    initial begin
        $dumpfile("multiplier.vcd");
        $dumpvars(0, tb_booth_multiplier);
    end

    // verificare
    task check;
        input [15:0] exp_prod;
        input [255:0] label;
        begin
            wait(done);
            #5;
            $display("%0s", label);
            $display("M=%0d Q=%0d", $signed(M), $signed(Q));
            $display("Product=%0d", $signed(Product));
            $display("%0s\n", ($signed(Product) == exp_prod) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        $display("Testare Modul Inmultire\n");

        clk = 0; rst = 1; start = 0;
        #10 rst = 0;

        // 1. calcul normal
        M = 8'd5; Q = 8'd3;
        start = 1; #10 start = 0;
        check(16'd15, "1. calcul normal: 5 * 3");

        // 2. alt calcul
        M = 8'd10; Q = 8'd4;
        start = 1; #10 start = 0;
        check(16'd40, "2. calcul normal: 10 * 4");

        // 3. zero
        M = 8'd0; Q = 8'd25;
        start = 1; #10 start = 0;
        check(16'd0, "3. situatie zero: 0 * 25");

        // 4. negativ (Booth)
        M = -8'd5; Q = 8'd3;
        start = 1; #10 start = 0;
        check(-16'd15, "4. situatie cu semn: -5 * 3");

        $display("Final testare modul inmultire");
        $finish;
    end

endmodule