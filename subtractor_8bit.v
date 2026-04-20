module subtractor_8bit (
input  wire [7:0] A,       // Descăzutul
input  wire [7:0] B,       // Scăzătorul
input  wire       enable,  // Activare circuit
output wire [7:0] Diff,    // Rezultatul scăderii (A - B)
output wire       Bout     // Borrow-out (împrumut)
);

```
// B inversat (complement față de 1)
wire [7:0] B_inv;

// Carry-out de la adunător
wire       adder_cout;

// Rezultatul brut al adunării
wire [7:0] raw_diff;

// Inversăm fiecare bit din B
not n0 (B_inv[0], B[0]);
not n1 (B_inv[1], B[1]);
not n2 (B_inv[2], B[2]);
not n3 (B_inv[3], B[3]);
not n4 (B_inv[4], B[4]);
not n5 (B_inv[5], B[5]);
not n6 (B_inv[6], B[6]);
not n7 (B_inv[7], B[7]);

// Adunător pe 8 biți:
// A + (~B) + 1 = A - B
adder_8bit adder_sub (
    .A(A), 
    .B(B_inv), 
    .Cin(1'b1),       // +1 pentru complement față de 2
    .enable(1'b1),    
    .Sum(raw_diff), 
    .Cout(adder_cout)
);

// Borrow-out:
// dacă Cout = 0 → a fost nevoie de împrumut
wire raw_bout;
not nb (raw_bout, adder_cout);

// Ieșirile sunt active doar dacă enable = 1
assign Diff = enable ? raw_diff : 8'bz;
assign Bout = enable ? raw_bout : 1'bz;
```

endmodule
