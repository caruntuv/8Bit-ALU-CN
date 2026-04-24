module subtractor_8bit (
    input  wire [7:0] A,        // operand a
    input  wire [7:0] B,        // operand b
    input  wire       enable,   // activare iesiri
    output wire [7:0] Diff,     // diferenta
    output wire       Bout      // borrow out
);
    wire [7:0] B_inv;           // b inversat
    wire       adder_cout;      // carry din adder
    wire [7:0] raw_diff;        // diferenta interna

    not n0 (B_inv[0], B[0]);    // inversare bit 0
    not n1 (B_inv[1], B[1]);    // inversare bit 1
    not n2 (B_inv[2], B[2]);    // inversare bit 2
    not n3 (B_inv[3], B[3]);    // inversare bit 3
    not n4 (B_inv[4], B[4]);    // inversare bit 4
    not n5 (B_inv[5], B[5]);    // inversare bit 5
    not n6 (B_inv[6], B[6]);    // inversare bit 6
    not n7 (B_inv[7], B[7]);    // inversare bit 7

    adder_8bit adder_sub (
        .A(A), .B(B_inv), .Cin(1'b1),       // a + b inversat + 1
        .enable(1'b1),                      // adder activ
        .Sum(raw_diff), .Cout(adder_cout)   // rezultat adder
    );

    wire raw_bout;              // borrow intern

    not nb (raw_bout, adder_cout); // borrow = not carry

    assign Diff = enable ? raw_diff  : 8'bz; // diferenta sau high-z
    assign Bout = enable ? raw_bout  : 1'bz; // borrow sau high-z
endmodule