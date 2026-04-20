module subtractor_8bit (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire       enable,
    output wire [7:0] Diff,
    output wire       Bout        
);
    wire [7:0] B_inv;
    wire       adder_cout;
    wire [7:0] raw_diff;
    not n0 (B_inv[0], B[0]);
    not n1 (B_inv[1], B[1]);
    not n2 (B_inv[2], B[2]);
    not n3 (B_inv[3], B[3]);
    not n4 (B_inv[4], B[4]);
    not n5 (B_inv[5], B[5]);
    not n6 (B_inv[6], B[6]);
    not n7 (B_inv[7], B[7]);
    adder_8bit adder_sub (
        .A(A), .B(B_inv), .Cin(1'b1),
        .enable(1'b1),          
        .Sum(raw_diff), .Cout(adder_cout)
    );
    wire raw_bout;
    not nb (raw_bout, adder_cout);
    assign Diff = enable ? raw_diff  : 8'bz;
    assign Bout = enable ? raw_bout  : 1'bz;
endmodule
