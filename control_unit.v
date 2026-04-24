// unitate de control fsm
// fara always
// stare salvata in 3 dff-uri
module control_unit (
    input  wire        clk,        // ceas
    input  wire        rst,        // reset
    input  wire [1:0]  op,         // cod operatie
    input  wire        start,      // pornire
    input  wire        mul_done,   // inmultire gata
    input  wire        div_done,   // impartire gata
    output wire        ra_load,    // incarcare registru a
    output wire        rb_load,    // incarcare registru b
    output wire        rc_load,    // incarcare rezultat
    output wire        ra_oe,      // iesire registru a
    output wire        rb_oe,      // iesire registru b
    output wire        rc_oe,      // iesire rezultat
    output wire        add_en,     // enable adunare
    output wire        sub_en,     // enable scadere
    output wire        mul_start,  // start inmultire
    output wire        div_start,  // start impartire
    output wire        alu_done    // alu gata
);
    // coduri stari
    localparam [2:0]
        S_IDLE  = 3'd0,   // asteptare
        S_LOAD  = 3'd1,   // incarcare
        S_EXEC  = 3'd2,   // executie
        S_WAIT  = 3'd3,   // asteptare operatie
        S_STORE = 3'd4,   // salvare rezultat
        S_DONE  = 3'd5;   // final

    wire [2:0] state;     // stare curenta
    wire [2:0] ns;        // stare urmatoare
    wire [2:0] ns_rst;    // stare dupa reset

    wire rst_n;           // reset negat
    not g_rstn (rst_n, rst);

    and g_nr0 (ns_rst[0], ns[0], rst_n); // reset bit 0
    and g_nr1 (ns_rst[1], ns[1], rst_n); // reset bit 1
    and g_nr2 (ns_rst[2], ns[2], rst_n); // reset bit 2

    dff_posedge dff0 (.clk(clk), .d(ns_rst[0]), .q(state[0])); // dff stare 0
    dff_posedge dff1 (.clk(clk), .d(ns_rst[1]), .q(state[1])); // dff stare 1
    dff_posedge dff2 (.clk(clk), .d(ns_rst[2]), .q(state[2])); // dff stare 2

    wire s0 = state[0]; // bit stare 0
    wire s1 = state[1]; // bit stare 1
    wire s2 = state[2]; // bit stare 2

    wire s0n, s1n, s2n; // biti negati
    not g_s0n (s0n, s0);
    not g_s1n (s1n, s1);
    not g_s2n (s2n, s2);

    wire in_idle, in_load, in_exec, in_wait, in_store, in_done; // stari decodate

    and g_idle  (in_idle,  s2n, s1n, s0n); // 000
    and g_load  (in_load,  s2n, s1n, s0);  // 001
    and g_exec  (in_exec,  s2n, s1,  s0n); // 010
    and g_wait  (in_wait,  s2n, s1,  s0);  // 011
    and g_store (in_store, s2,  s1n, s0n); // 100
    and g_done  (in_done,  s2,  s1n, s0);  // 101

    wire op0n, op1n; // op negati
    not g_op0n (op0n, op[0]);
    not g_op1n (op1n, op[1]);

    wire is_add, is_sub, is_mul, is_div, fast_op; // operatii decodate
    and g_add  (is_add, op1n,  op0n);  // op 00
    and g_sub  (is_sub, op1n,  op[0]); // op 01
    and g_mul  (is_mul, op[1], op0n);  // op 10
    and g_div  (is_div, op[1], op[0]); // op 11
    or  g_fast (fast_op, is_add, is_sub); // operatii rapide

    wire go_load;        // trecere la load
    wire go_exec;        // trecere la exec
    wire go_store_fast;  // salvare rapida
    wire go_wait;        // trecere la wait
    wire wait_done;      // asteptare gata
    wire go_store_wait;  // salvare dupa wait
    wire go_done;        // trecere la done
    wire go_idle;        // trecere la idle

    wire fast_op_n; // operatie lenta
    not  g_fastn (fast_op_n, fast_op);

    and  g_gl   (go_load,       in_idle, start); // idle -> load
    assign       go_exec      = in_load;         // load -> exec
    and  g_gsf  (go_store_fast, in_exec, fast_op); // exec -> store
    and  g_gw   (go_wait,       in_exec, fast_op_n); // exec -> wait

    wire mul_ok, div_ok; // final operatii lente
    and  g_mok  (mul_ok,        is_mul, mul_done);
    and  g_dok  (div_ok,        is_div, div_done);
    or   g_wd   (wait_done,     mul_ok, div_ok);
    and  g_gsw  (go_store_wait, in_wait, wait_done); // wait -> store

    assign       go_done = in_store; // store -> done
    assign       go_idle = in_done;  // done -> idle

    wire wait_done_n, stay_wait; // ramanere in wait
    not  g_wdn   (wait_done_n, wait_done);
    and  g_sw    (stay_wait,   in_wait, wait_done_n);

    or   g_ns0  (ns[0], go_load, go_wait, stay_wait, go_done); // bit ns 0
    or   g_ns1  (ns[1], go_exec, go_wait, stay_wait);          // bit ns 1

    wire go_store; // trecere la store
    or   g_gs   (go_store, go_store_fast, go_store_wait);
    or   g_ns2  (ns[2], go_store, go_done); // bit ns 2

    assign ra_load   = in_load;                     // incarca a
    assign rb_load   = in_load;                     // incarca b
    assign rc_load   = in_store;                    // incarca rezultat
    assign ra_oe     = in_exec | in_wait | in_store; // activeaza a
    assign rb_oe     = in_exec | in_wait | in_store; // activeaza b
    assign rc_oe     = in_store | in_done;          // activeaza rezultat
    assign add_en    = (in_exec | in_store) & is_add; // enable adder
    assign sub_en    = (in_exec | in_store) & is_sub; // enable subtractor
    assign mul_start = in_exec & is_mul;            // porneste inmultire
    assign div_start = in_exec & is_div;            // porneste impartire
    assign alu_done  = in_done;                     // operatie gata

endmodule