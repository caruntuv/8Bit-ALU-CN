// single positive-edge-triggered D flip-flop.
// basically the simplest storage element, updates only on rising clock edge.
// this is used everywhere in the design to build registers.
module dff_posedge (
    output reg q,   // stored value
    input      clk, // clock signal
    input      d    // input data
);
    // on every positive edge of clock, store the value of d into q
    always @(posedge clk) q <= d;
endmodule