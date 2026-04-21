// Positive-edge D flip-flop implemented as a User Defined Primitive (UDP)
// UDPs allow defining custom gate behavior using a truth table
primitive dff_posedge (output reg q, input clk, input d);
    table
    //  clk   d  :  q  :  q+
        (01)  0  :  ?  :  0 ;   // rising edge, d=0 -> q becomes 0
        (01)  1  :  ?  :  1 ;   // rising edge, d=1 -> q becomes 1
        (0x)  1  :  1  :  1 ;   // clk uncertain, d=1, q=1 -> hold
        (0x)  0  :  0  :  0 ;   // clk uncertain, d=0, q=0 -> hold
        (?0)  ?  :  ?  :  - ;   // falling or stable clk -> hold q
        ?    (?):  ?  :  - ;    // d changes but clk not rising -> hold q
    endtable
endprimitive

module register_8bit (
    input  wire        clk,
    input  wire        rst,
    input  wire        load,
    input  wire        oe,
    input  wire [7:0]  D,
    output wire [7:0]  Q
);
    wire [7:0] data;
    wire [7:0] d_next;
    wire [7:0] dff_d;
    wire load_n;
    wire rst_n;

    not g_load_n (load_n, load);
    not g_rst_n  (rst_n,  rst);

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bit_cell
            wire mux_new, mux_keep, mux_out;
            // Mux: if load=1 take D[i], else keep data[i]
            and g_new  (mux_new,  D[i],    load);
            and g_keep (mux_keep, data[i], load_n);
            or  g_next (mux_out,  mux_new, mux_keep);
            // If rst=1, force 0 into the DFF
            and g_dff  (dff_d[i], mux_out, rst_n);
            // Instantiate one DFF per bit
            dff_posedge dff_inst (.clk(clk), .d(dff_d[i]), .q(data[i]));
        end
    endgenerate

    assign Q = oe ? data : 8'bz;
endmodule
