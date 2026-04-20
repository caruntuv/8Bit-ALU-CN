module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    wire xor1, and1, and2;
    xor g1 (xor1, a, b);// defineste poarta xor intre a si b
    xor g2 (sum,  xor1, cin);// suma= (a xor b) xor cin
    and g3 (and1, a, b);
    and g4 (and2, xor1, cin);
    or  g5 (cout, and1, and2);//carryoutul= (a AND b) OR ((a XOR b) AND cin)
endmodule
