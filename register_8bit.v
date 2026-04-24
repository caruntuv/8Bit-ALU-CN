// registru pe 8 biti
// load, output enable si reset sincron
// construit din dff-uri si porti
module register_8bit (
    input  wire        clk,     // ceas
    input  wire        rst,     // reset
    input  wire        load,    // incarcare
    input  wire        oe,      // activare iesire
    input  wire [7:0]  D,       // date intrare
    output wire [7:0]  Q        // date iesire
);
    wire [7:0] stored;   // valori memorate
    wire [7:0] dff_d;    // intrari dff
    wire load_n, rst_n;  // semnale negate

    not g_load_n (load_n, load); // not load
    not g_rst_n  (rst_n,  rst);  // not reset

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bit_cell
            wire sel_D, sel_Q, mux_out; // semnale pe bit

            and g_selD (sel_D,  D[i],      load);   // selecteaza d
            and g_selQ (sel_Q,  stored[i], load_n); // pastreaza vechi
            or  g_mux  (mux_out, sel_D, sel_Q);     // iesire mux

            and g_rst  (dff_d[i], mux_out, rst_n);  // reset sincron

            dff_posedge dff (.clk(clk), .d(dff_d[i]), .q(stored[i])); // dff bit
        end
    endgenerate

    assign Q = oe ? stored : 8'bz; // iesire sau high-z
endmodule