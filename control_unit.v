// control unit for the 8bit alu — no always blocks
// state is 3 dffs, everything else is just gates and assign statements
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
    // state encoding, 3 bits, binary
    localparam [2:0]
        S_IDLE  = 3'd0,  
        S_LOAD  = 3'd1,   
        S_EXEC  = 3'd2,   
        S_WAIT  = 3'd3,   
        S_STORE = 3'd4,   
        S_DONE  = 3'd5;   

    // state register — 3 dffs, one per bit
    wire [2:0] state;
    wire [2:0] ns;       // next state, combinational
    wire [2:0] ns_rst;   // next state gated by reset

    wire rst_n;
    not g_rstn (rst_n, rst);

    // reset forces state to 000 by killing all ns bits
    and g_nr0 (ns_rst[0], ns[0], rst_n);
    and g_nr1 (ns_rst[1], ns[1], rst_n);
    and g_nr2 (ns_rst[2], ns[2], rst_n);

    dff_posedge dff0 (.clk(clk), .d(ns_rst[0]), .q(state[0]));
    dff_posedge dff1 (.clk(clk), .d(ns_rst[1]), .q(state[1]));
    dff_posedge dff2 (.clk(clk), .d(ns_rst[2]), .q(state[2]));

    // decode current state — one wire per state, goes high when we re in it
    wire s0 = state[0];
    wire s1 = state[1];
    wire s2 = state[2];
    wire s0n, s1n, s2n;
    not g_s0n (s0n, s0);
    not g_s1n (s1n, s1);
    not g_s2n (s2n, s2);

    wire in_idle, in_load, in_exec, in_wait, in_store, in_done;
    and g_idle  (in_idle,  s2n, s1n, s0n);     
    and g_load  (in_load,  s2n, s1n, s0);      
    and g_exec  (in_exec,  s2n, s1,  s0n);      
    and g_wait  (in_wait,  s2n, s1,  s0);       
    and g_store (in_store, s2,  s1n, s0n);      
    and g_done  (in_done,  s2,  s1n, s0);       

    // decode op — figure out which operation we re doing
    wire op0n, op1n;
    not g_op0n (op0n, op[0]);
    not g_op1n (op1n, op[1]);

    wire is_add, is_sub, is_mul, is_div, fast_op;
    and g_add  (is_add, op1n,  op0n);    
    and g_sub  (is_sub, op1n,  op[0]);   
    and g_mul  (is_mul, op[1], op0n);    
    and g_div  (is_div, op[1], op[0]);   
    or  g_fast (fast_op, is_add, is_sub);

    // transition conditions — one wire per edge in the fsm
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
    assign       go_exec      = in_load;
    and  g_gsf  (go_store_fast, in_exec, fast_op);
    and  g_gw   (go_wait,       in_exec, fast_op_n);

    wire mul_ok, div_ok;
    and  g_mok  (mul_ok,        is_mul, mul_done);
    and  g_dok  (div_ok,        is_div, div_done);
    or   g_wd   (wait_done,     mul_ok, div_ok);
    and  g_gsw  (go_store_wait, in_wait, wait_done);

    assign       go_done = in_store;
    assign       go_idle = in_done;

    // next state logic
    // each ns bit is OR of all transitions that land in a state with that bit set
   
    // idle and wait are the only states that can hold
    wire wait_done_n, stay_wait;
    not  g_wdn   (wait_done_n, wait_done);
    and  g_sw    (stay_wait,   in_wait, wait_done_n);

    or   g_ns0  (ns[0], go_load, go_wait, stay_wait, go_done);  // bit0
    or   g_ns1  (ns[1], go_exec, go_wait, stay_wait);           // bit1
    wire go_store;
    or   g_gs   (go_store, go_store_fast, go_store_wait);
    or   g_ns2  (ns[2], go_store, go_done);                     // bit2

    // outputs — purely combinational, just decode the current state
    assign ra_load   = in_load;
    assign rb_load   = in_load;
    assign rc_load   = in_store;
    assign ra_oe     = in_exec | in_wait | in_store;
    assign rb_oe     = in_exec | in_wait | in_store;
    assign rc_oe     = in_store | in_done | in_idle; // keep outbus valid in idle so tb can read it
    assign add_en    = (in_exec | in_store) & is_add;
    assign sub_en    = (in_exec | in_store) & is_sub;
    assign mul_start = in_exec & is_mul;
    assign div_start = in_exec & is_div;
    assign alu_done  = in_done;

endmodule