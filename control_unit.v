// Control unit FSM — fully structural.
// state[2:0] is the only sequential element, implemented with 3 dff_posedge instances.
// All next-state and output logic is purely combinational (assign statements).
// No always blocks anywhere in this module.
module control_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  op,
    input  wire        start,
    input  wire        mul_done,
    input  wire        div_done,
    output wire        ra_load,
    output wire        rb_load,
    output wire        rc_load,
    output wire        ra_oe,
    output wire        rb_oe,
    output wire        rc_oe,
    output wire        add_en,
    output wire        sub_en,
    output wire        mul_start,
    output wire        div_start,
    output wire        alu_done
);
    // State encoding (3-bit one-hot friendly binary)
    localparam [2:0]
        S_IDLE  = 3'd0,   // 000
        S_LOAD  = 3'd1,   // 001
        S_EXEC  = 3'd2,   // 010
        S_WAIT  = 3'd3,   // 011
        S_STORE = 3'd4,   // 100
        S_DONE  = 3'd5;   // 101

    // -----------------------------------------------------------------------
    // State register: 3 DFF instances (the only sequential elements)
    // -----------------------------------------------------------------------
    wire [2:0] state;
    wire [2:0] ns;       // next_state computed combinationally below
    wire [2:0] ns_rst;   // next_state gated by reset (rst forces S_IDLE = 000)

    wire rst_n;
    not g_rstn (rst_n, rst);

    // rst forces all state bits to 0 (S_IDLE) by ANDing each ns bit with rst_n
    and g_nr0 (ns_rst[0], ns[0], rst_n);
    and g_nr1 (ns_rst[1], ns[1], rst_n);
    and g_nr2 (ns_rst[2], ns[2], rst_n);

    dff_posedge dff0 (.clk(clk), .d(ns_rst[0]), .q(state[0]));
    dff_posedge dff1 (.clk(clk), .d(ns_rst[1]), .q(state[1]));
    dff_posedge dff2 (.clk(clk), .d(ns_rst[2]), .q(state[2]));

    // -----------------------------------------------------------------------
    // Current-state decode
    // Each in_X wire is 1 only when we are in that state.
    // Using the binary encoding: compare state against each constant.
    // -----------------------------------------------------------------------
    wire s0 = state[0];
    wire s1 = state[1];
    wire s2 = state[2];
    wire s0n, s1n, s2n;
    not g_s0n (s0n, s0);
    not g_s1n (s1n, s1);
    not g_s2n (s2n, s2);

    wire in_idle, in_load, in_exec, in_wait, in_store, in_done;
    and g_idle  (in_idle,  s2n, s1n, s0n);      // 000
    and g_load  (in_load,  s2n, s1n, s0);       // 001
    and g_exec  (in_exec,  s2n, s1,  s0n);      // 010
    and g_wait  (in_wait,  s2n, s1,  s0);       // 011
    and g_store (in_store, s2,  s1n, s0n);      // 100
    and g_done  (in_done,  s2,  s1n, s0);       // 101

    // -----------------------------------------------------------------------
    // Op decode
    // -----------------------------------------------------------------------
    wire op0n, op1n;
    not g_op0n (op0n, op[0]);
    not g_op1n (op1n, op[1]);

    wire is_add, is_sub, is_mul, is_div, fast_op;
    and g_add  (is_add, op1n,  op0n);    // op == 00
    and g_sub  (is_sub, op1n,  op[0]);   // op == 01
    and g_mul  (is_mul, op[1], op0n);    // op == 10
    and g_div  (is_div, op[1], op[0]);   // op == 11
    or  g_fast (fast_op, is_add, is_sub);

    // -----------------------------------------------------------------------
    // Transition conditions
    // -----------------------------------------------------------------------
    wire go_load;        // IDLE -> LOAD
    wire go_exec;        // LOAD -> EXEC  (unconditional from LOAD)
    wire go_store_fast;  // EXEC -> STORE (fast op)
    wire go_wait;        // EXEC -> WAIT  (slow op)
    wire wait_done;      // WAIT -> STORE (mul/div finished)
    wire go_store_wait;  // WAIT -> STORE
    wire go_done;        // STORE -> DONE (unconditional)
    wire go_idle;        // DONE -> IDLE  (unconditional)

    wire fast_op_n;
    not  g_fastn (fast_op_n, fast_op);

    and  g_gl   (go_load,       in_idle, start);
    assign       go_exec      = in_load;          // always advance
    and  g_gsf  (go_store_fast, in_exec, fast_op);
    and  g_gw   (go_wait,       in_exec, fast_op_n);

    wire mul_ok, div_ok;
    and  g_mok  (mul_ok,        is_mul, mul_done);
    and  g_dok  (div_ok,        is_div, div_done);
    or   g_wd   (wait_done,     mul_ok, div_ok);
    and  g_gsw  (go_store_wait, in_wait, wait_done);

    assign       go_done = in_store;              // always advance
    assign       go_idle = in_done;              // always advance

    // -----------------------------------------------------------------------
    // Next-state encoding
    // Each state bit is the OR of all conditions that lead to a state with
    // that bit set.
    //
    //  S_IDLE  = 000  -> no bits set  (default / go_idle)
    //  S_LOAD  = 001  -> bit0
    //  S_EXEC  = 010  -> bit1
    //  S_WAIT  = 011  -> bit1, bit0
    //  S_STORE = 100  -> bit2
    //  S_DONE  = 101  -> bit2, bit0
    //
    // Hold conditions (stay in same state):
    //   IDLE  stays when !start         -> bits stay 000
    //   WAIT  stays when !wait_done     -> bits stay 011
    // -----------------------------------------------------------------------
    wire wait_done_n, stay_wait;
    not  g_wdn   (wait_done_n, wait_done);
    and  g_sw    (stay_wait,   in_wait, wait_done_n);

    // bit 0: set by -> S_LOAD(go_load), S_WAIT(go_wait or stay_wait), S_DONE(go_done)
    or   g_ns0  (ns[0], go_load, go_wait, stay_wait, go_done);

    // bit 1: set by -> S_EXEC(go_exec), S_WAIT(go_wait or stay_wait)
    or   g_ns1  (ns[1], go_exec, go_wait, stay_wait);

    // bit 2: set by -> S_STORE(go_store_fast or go_store_wait), S_DONE(go_done)
    wire go_store;
    or   g_gs   (go_store, go_store_fast, go_store_wait);
    or   g_ns2  (ns[2], go_store, go_done);

    // -----------------------------------------------------------------------
    // Output logic (purely combinational assign)
    // -----------------------------------------------------------------------
    assign ra_load   = in_load;
    assign rb_load   = in_load;
    assign rc_load   = in_store;
    assign ra_oe     = in_exec | in_wait | in_store;
    assign rb_oe     = in_exec | in_wait | in_store;
    assign rc_oe     = in_store | in_done;
    assign add_en    = (in_exec | in_store) & is_add;
    assign sub_en    = (in_exec | in_store) & is_sub;
    assign mul_start = in_exec & is_mul;
    assign div_start = in_exec & is_div;
    assign alu_done  = in_done;

endmodule
