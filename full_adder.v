module full_adder (
    input  wire a,      // bit a
    input  wire b,      // bit b
    input  wire cin,    // carry in
    output wire sum,    // suma bitului
    output wire cout    // carry out
);
    wire xor1, and1, and2; // fire interne

    xor g1 (xor1, a, b);       // a xor b
    xor g2 (sum,  xor1, cin);  // suma finala
    and g3 (and1, a, b);       // a si b
    and g4 (and2, xor1, cin);  // xor1 si cin
    or  g5 (cout, and1, and2); // carry final
endmodule