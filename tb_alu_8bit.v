`timescale 1ns/1ps
module tb_alu_8bit;

    reg        clk, rst, start;
    reg  [1:0] op;
    reg  [7:0] A_in, B_in;
    wire [15:0] OUTBUS;
    wire        alu_done;

    integer i;
    reg [15:0] expected;

    alu_8bit DUT (
        .clk(clk), .rst(rst), .op(op), .start(start),
        .A_in(A_in), .B_in(B_in),
        .OUTBUS(OUTBUS), .alu_done(alu_done)
    );

    // clock
    always #5 clk = ~clk;

    // waveform
    initial begin
        $dumpfile("alu_top.vcd");
        $dumpvars(0, tb_alu_8bit);
    end

    task check;
        input [1:0]   operation;
        input [7:0]   a;
        input [7:0]   b;
        input [15:0]  expected_value;
        input [255:0] label;
        input [255:0] operatie_text;
        begin
            op = operation;
            A_in = a;
            B_in = b;

            start = 1; #10;
            start = 0;

            wait(alu_done);
            #10;

            $display("%0s", label);
            $display("selectie: op=%b -> %0s", operation, operatie_text);
            $display("A=%0d B=%0d", a, b);
            $display("OUTBUS=%0d", OUTBUS);
            $display("%0s\n", (OUTBUS == expected_value) ? "PASS" : "FAIL");

            #10;
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        op = 0;
        A_in = 0;
        B_in = 0;

        #15;
        rst = 0;

        $display("Testare ALU Top Level\n");

        $display("Selectie operatii:");
        $display("op=00 -> adunare");
        $display("op=01 -> scadere");
        $display("op=10 -> inmultire");
        $display("op=11 -> impartire\n");

        // adunare
        check(2'b00, 8'd10, 8'd20, 16'd30,
              "1. adunare normala: 10 + 20",
              "adunare");

        check(2'b00, 8'd255, 8'd1, 16'd256,
              "2. adunare speciala: 255 + 1",
              "adunare overflow");

        // scadere
        check(2'b01, 8'd20, 8'd10, 16'd10,
              "3. scadere normala: 20 - 10",
              "scadere");

        check(2'b01, 8'd10, 8'd20, {8'd1, 8'd246},
              "4. scadere speciala: 10 - 20",
              "scadere cu borrow");

        // inmultire
        check(2'b10, 8'd5, 8'd3, 16'd15,
              "5. inmultire normala: 5 * 3",
              "inmultire");

        check(2'b10, 8'd0, 8'd25, 16'd0,
              "6. inmultire speciala: 0 * 25",
              "inmultire cu zero");

        // impartire
        check(2'b11, 8'd20, 8'd4, {8'd5, 8'd0},
              "7. impartire normala: 20 / 4",
              "impartire");

        check(2'b11, 8'd22, 8'd5, {8'd4, 8'd2},
              "8. impartire speciala: 22 / 5",
              "impartire cu rest");

        // stress test random
        $display("Test random ALU\n");

        for (i = 0; i < 5; i = i + 1) begin
            op   = $random % 4;
            A_in = $random % 16;
            B_in = $random % 16;

            // evitam impartirea la zero in test random
            if (op == 2'b11 && B_in == 0)
                B_in = 8'd1;

            case (op)
                2'b00: expected = A_in + B_in; // adunare
                2'b01: expected = {7'b0, (A_in < B_in), (A_in - B_in)}; // scadere
                2'b10: expected = A_in * B_in; // inmultire
                2'b11: expected = {A_in / B_in, A_in % B_in}; // impartire
            endcase

            start = 1; #10;
            start = 0;

            wait(alu_done);
            #10;

            $display("random %0d", i);
            $display("selectie: op=%b", op);
            $display("A=%0d B=%0d", A_in, B_in);
            $display("OUTBUS=%0d expected=%0d", OUTBUS, expected);
            $display("%0s\n", (OUTBUS == expected) ? "PASS" : "FAIL");

            #10;
        end

        $display("Final testare ALU Top Level");
        $finish;
    end

endmodule