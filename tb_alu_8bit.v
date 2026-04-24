`timescale 1ns/1ps
// tb for the 8bit alu, modelsim version
module tb_alu_8bit_modelsim;

    // alu inputs/outputs
    reg         clk;
    reg         rst;
    reg         start;
    reg  [1:0]  op;
    reg  [7:0]  A_in;
    reg  [7:0]  B_in;
    wire [15:0] OUTBUS;
    wire        alu_done;

    // shows which test is running in the waveform, and if it passed
    reg [63:0] test_label;
    reg        pass;

    // dut
    alu_8bit DUT (
        .clk(clk), .rst(rst), .op(op), .start(start),
        .A_in(A_in), .B_in(B_in),
        .OUTBUS(OUTBUS), .alu_done(alu_done)
    );

    // clock, 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // dump everything for the waveform
    initial begin
        $dumpfile("tb_alu_8bit.vcd");
        $dumpvars(0, tb_alu_8bit_modelsim);
    end

    // runs one operation and checks the result
    // start is asserted on negedge so the fsm catches it on the next posedge
    // outbus is sampled one cycle after alu_done while the fsm is still in S_DONE
    task run_op;
        input [1:0]  operation;
        input [7:0]  a, b;
        input [15:0] exp;
        input [63:0] lbl;
        begin
            test_label = lbl;
            op   = operation;
            A_in = a;
            B_in = b;
            pass = 0;

            @(negedge clk); start = 1;
            @(negedge clk); start = 0;

            @(posedge alu_done);
            @(posedge clk); #1;

            pass = (OUTBUS === exp) ? 1 : 0;
            $display("[%0s]  A=%0d  B=%0d  =>  OUTBUS=%0d  (exp=%0d)  %0s",
                     lbl, a, b, OUTBUS, exp, pass ? "PASS" : "FAIL");

            @(negedge clk);
        end
    endtask

    initial begin
        rst = 1; start = 0; op = 0; A_in = 0; B_in = 0;
        test_label = "INIT    "; pass = 0;

        // reset for 2 cycles then release
        @(negedge clk);
        @(negedge clk);
        rst = 0;

        $display("=== ALU 8-bit Testbench ===");

        // add
        run_op(2'b00,  8'd30,  8'd12,  16'd42,         "ADD     ");
        run_op(2'b00,  8'd200, 8'd100, 16'd300,         "ADD_OVF ");

        // sub
        run_op(2'b01,  8'd50,  8'd20,  16'd30,          "SUB     ");
        run_op(2'b01,  8'd10,  8'd20,  {8'd1, 8'd246},  "SUB_BRW "); // borrows, Bout=1

        // mul
        run_op(2'b10,  8'd6,   8'd7,   16'd42,          "MUL     ");
        run_op(2'b10,  8'd15,  8'd15,  16'd225,         "MUL_15  ");
        run_op(2'b10,  8'd0,   8'd99,  16'd0,           "MUL_ZERO");

        // div — quotient in [15:8], remainder in [7:0]
        run_op(2'b11,  8'd42,  8'd6,   {8'd7,  8'd0},   "DIV     ");
        run_op(2'b11,  8'd100, 8'd7,   {8'd14, 8'd2},   "DIV_REM ");
        run_op(2'b11,  8'd1,   8'd1,   {8'd1,  8'd0},   "DIV_ONE ");

        $display("=== done ===");

        repeat(4) @(posedge clk);
        $finish;
    end

endmodule
