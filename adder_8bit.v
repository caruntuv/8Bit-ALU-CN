module adder_8bit (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire       Cin,
    input  wire       enable,       
    output wire [7:0] Sum,
    output wire       Cout
);
    wire [6:0] carry;//bitii de carry folositi la fiecare pas
    wire [7:0] raw_sum;//suma inainte enable
    wire       raw_cout;
    full_adder fa0 (.a(A[0]), .b(B[0]), .cin(Cin),     .sum(raw_sum[0]), .cout(carry[0]));
    full_adder fa1 (.a(A[1]), .b(B[1]), .cin(carry[0]), .sum(raw_sum[1]), .cout(carry[1]));
    full_adder fa2 (.a(A[2]), .b(B[2]), .cin(carry[1]), .sum(raw_sum[2]), .cout(carry[2]));
    full_adder fa3 (.a(A[3]), .b(B[3]), .cin(carry[2]), .sum(raw_sum[3]), .cout(carry[3]));
    full_adder fa4 (.a(A[4]), .b(B[4]), .cin(carry[3]), .sum(raw_sum[4]), .cout(carry[4]));
    full_adder fa5 (.a(A[5]), .b(B[5]), .cin(carry[4]), .sum(raw_sum[5]), .cout(carry[5]));
    full_adder fa6 (.a(A[6]), .b(B[6]), .cin(carry[5]), .sum(raw_sum[6]), .cout(carry[6]));
    full_adder fa7 (.a(A[7]), .b(B[7]), .cin(carry[6]), .sum(raw_sum[7]), .cout(raw_cout));
    //Ripple carry adder pe 8 biti, mai sus este instantiat un full adder pentru fiecare bit insumat ce foloseste un bit din cei 7 de caryy
    assign Sum  = enable ? raw_sum  : 8'bz;// z high impedance
    assign Cout = enable ? raw_cout : 1'bz;
    //rezultatele dupa enable
endmodule
