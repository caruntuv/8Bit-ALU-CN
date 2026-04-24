//1-bit full adder 
module full_adder (
    input  wire a,    
    input  wire b,     
    input  wire cin,   
    output wire sum,   
    output wire cout   
);
    // internal wires for intermediate results
    wire xor1, and1, and2;

    // first XOR: a ^ b
    xor g1 (xor1, a, b);

    // second XOR: (a ^ b) ^ cin -> final sum
    xor g2 (sum,  xor1, cin);

    // a & b
    and g3 (and1, a, b);

    //(a ^ b) & cin
    and g4 (and2, xor1, cin);

    //  final carry out
    or  g5 (cout, and1, and2);
endmodule