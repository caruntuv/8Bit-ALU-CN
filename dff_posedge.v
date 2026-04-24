// flip-flop d pe front pozitiv
// singurul always din proiect
// folosit pentru registre
module dff_posedge (
    output reg q,    // iesire memorata
    input      clk,  // semnal ceas
    input      d     // intrare date
);
    always @(posedge clk) q <= d; // salveaza d la front pozitiv
endmodule