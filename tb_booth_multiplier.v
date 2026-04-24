`timescale 1ns/1ps
//test bench for multiplier
module tb_booth_multiplier;
    reg        clk, rst, start, enable;
    reg  [7:0] M, Q;
    wire [15:0] Product;
    wire        done;

    booth_multiplier DUT (
        .clk(clk), .rst(rst), .start(start), .enable(enable),
        .M(M), .Q(Q), .Product(Product), .done(done)
    );
//clock
    always #5 clk = ~clk;
//helper task for multiplication
//uses signed values to match booth behavior
    task check;
        input signed [7:0]  m_in, q_in;
        input signed [15:0] expected;
        begin
            M=m_in; Q=q_in; start=1; #10; start=0;
            wait(done); #10;
            $display("[MUL] %0d x %0d => %0d | exp=%0d | %0s",
                $signed(m_in), $signed(q_in),
                $signed(Product), $signed(expected),
                ($signed(Product) == $signed(expected)) ? "PASS" : "FAIL");
        end
    endtask
//test
    initial begin
      //init and reset
        clk=0; rst=1; start=0; enable=1; M=0; Q=0;
        #15; rst=0;
        $display("=== Booth Multiplier Testbench ===");
        //basic positive case
        check( 8'd5,   8'd3,   16'd15);
        //negative * positive
        check( 8'hFC,  8'd3,   16'hFFF4);   // -4 x 3 = -12
        check( 8'd7,   8'hFE,  16'hFFF2);   //  7 x -2 = -14
        //0 case
        check( 8'd0,   8'd255, 16'd0);
        //large val
        check( 8'd15,  8'd15,  16'd225);
        $display("=== Done ===");
        $finish;
    end
endmodule