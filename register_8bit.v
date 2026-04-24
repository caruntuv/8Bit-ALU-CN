// 8-bit register
// using 8 D flip-flops and basic gates (no always blocks).
module register_8bit (
    input  wire        clk,   
    input  wire        rst,   
    input  wire        load,  
    input  wire        oe,    
    input  wire [7:0]  D,     
    output wire [7:0]  Q      
);
    // stored values inside the register (outputs of DFFs)
    wire [7:0] stored;

    wire [7:0] dff_d;

    wire load_n, rst_n;

    not g_load_n (load_n, load);
    not g_rst_n  (rst_n,  rst);

    genvar i;
    generate
        // generate 8 identical bit cells
        for (i = 0; i < 8; i = i + 1) begin : bit_cell
            wire sel_D, sel_Q, mux_out;

            and g_selD (sel_D,  D[i],      load);
            and g_selQ (sel_Q,  stored[i], load_n);
            or  g_mux  (mux_out, sel_D, sel_Q);

            // reset logic:
            // if rst = 1 → force 0 into DFF
            and g_rst  (dff_d[i], mux_out, rst_n);

            // actual storage element (flip-flop)
            dff_posedge dff (.clk(clk), .d(dff_d[i]), .q(stored[i]));
        end
    endgenerate

    // output enable:
    // if oe = 1 → output stored value
    // if oe = 0 → high impedance (Z)
    assign Q = oe ? stored : 8'bz;
endmodule