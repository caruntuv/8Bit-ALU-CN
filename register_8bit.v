// 8-bit register: load-enable, output-enable, synchronous reset.
// Built entirely from dff_posedge primitives and gate-level logic.
// No always blocks.
module register_8bit (
    input  wire        clk,
    input  wire        rst,
    input  wire        load,
    input  wire        oe,
    input  wire [7:0]  D,
    output wire [7:0]  Q
);
    wire [7:0] stored;   // outputs of the 8 DFFs
    wire [7:0] dff_d;    // inputs  to  the 8 DFFs
    wire load_n, rst_n;

    not g_load_n (load_n, load);
    not g_rst_n  (rst_n,  rst);

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bit_cell
            wire sel_D, sel_Q, mux_out;
            // Mux: load=1 -> take D[i], load=0 -> keep stored[i]
            and g_selD (sel_D,  D[i],      load);
            and g_selQ (sel_Q,  stored[i], load_n);
            or  g_mux  (mux_out, sel_D, sel_Q);
            // Reset: rst=1 -> force 0 into DFF
            and g_rst  (dff_d[i], mux_out, rst_n);
            dff_posedge dff (.clk(clk), .d(dff_d[i]), .q(stored[i]));
        end
    endgenerate

    assign Q = oe ? stored : 8'bz;
endmodule
