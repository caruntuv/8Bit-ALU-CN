// Single positive-edge-triggered D flip-flop.
// This module contains the ONE and ONLY always block in the entire design.
// Every register in every module is built by instantiating this.
module dff_posedge (
    output reg q,
    input      clk,
    input      d
);
    always @(posedge clk) q <= d;
endmodule
