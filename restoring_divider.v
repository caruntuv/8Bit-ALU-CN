// Restoring divider — fully structural.
// Every register is built from dff_posedge primitives.
// No always blocks anywhere in this module.
module restoring_divider (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        enable,
    input  wire [7:0]  Dividend,
    input  wire [7:0]  Divisor,
    output wire [7:0]  Quotient,
    output wire [7:0]  Remainder,
    output wire        done,
    output wire        div_by_zero
);
    // -----------------------------------------------------------------------
    // Registered state
    // -----------------------------------------------------------------------
    wire [7:0] A;          // partial remainder
    wire [7:0] Q_reg;      // dividend / accumulating quotient
    wire [7:0] D_reg;      // latched divisor
    wire [3:0] count;      // step counter
    wire       running;
    wire [7:0] Quotient_r;
    wire [7:0] Remainder_r;
    wire       done_r;
    wire       dbz_r;      // div_by_zero register

    assign Quotient    = Quotient_r;
    assign Remainder   = Remainder_r;
    assign done        = done_r;
    assign div_by_zero = dbz_r;

    // -----------------------------------------------------------------------
    // Combinational: shift A left, bring in MSB of Q_reg
    // -----------------------------------------------------------------------
    wire [7:0] A_shift;
    assign A_shift = {A[6:0], Q_reg[7]};

    // Try subtracting D_reg from A_shift
    wire [7:0] sub_result;
    wire       sub_bout;
    subtractor_8bit suber (
        .A(A_shift), .B(D_reg), .enable(1'b1),
        .Diff(sub_result), .Bout(sub_bout)
    );

    // no_borrow=1: subtraction OK -> keep result, quotient bit=1
    // sub_bout=1:  underflow      -> restore A_shift,  quotient bit=0
    wire no_borrow;
    not g_nb (no_borrow, sub_bout);

    // Next A: no_borrow->sub_result, borrow->A_shift (restore)
    wire [7:0] A_next;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : a_mux
            wire w_keep, w_restore;
            and g_k (w_keep,    sub_result[i], no_borrow);
            and g_r (w_restore, A_shift[i],    sub_bout);
            or  g_o (A_next[i], w_keep, w_restore);
        end
    endgenerate

    // Next Q_reg: shift left, LSB = quotient bit (no_borrow)
    wire [7:0] Q_next;
    assign Q_next = {Q_reg[6:0], no_borrow};

    // -----------------------------------------------------------------------
    // Control conditions
    // -----------------------------------------------------------------------
    wire rst_n;
    not g_rstn (rst_n, rst);

    // div_zero = (Divisor == 0): NOR all 8 bits
    wire div_zero;
    nor g_dz (div_zero, Divisor[0], Divisor[1], Divisor[2], Divisor[3],
                        Divisor[4], Divisor[5], Divisor[6], Divisor[7]);

    wire running_n, start_new;
    not g_rn (running_n, running);
    and g_sn (start_new, start, running_n);

    // start_ok = start_new & !div_zero
    wire div_zero_n, start_ok;
    not g_dzn (div_zero_n, div_zero);
    and g_sok (start_ok, start_new, div_zero_n);

    // start_dbz = start_new & div_zero
    wire start_dbz;
    and g_sdbz (start_dbz, start_new, div_zero);

    // last_cycle: count==1 & running
    wire c3n, c2n, c1n, cnt_is_1;
    not g_c3n (c3n, count[3]);
    not g_c2n (c2n, count[2]);
    not g_c1n (c1n, count[1]);
    and g_lc  (cnt_is_1, c3n, c2n, c1n, count[0], running);

    wire step, cnt_is_1_n;
    not  g_lcn  (cnt_is_1_n, cnt_is_1);
    and  g_step (step, running, cnt_is_1_n);

    // -----------------------------------------------------------------------
    // Next-state for each register
    // Priority: rst > start_ok/start_dbz > step > hold
    // -----------------------------------------------------------------------

    // --- A (8 bits): rst->0, start_ok->0, step->A_next, else hold ---
    wire [7:0] A_reg_next;
    generate
        for (i = 0; i < 8; i = i + 1) begin : an
            wire w_step, w_hold, any_e, any_n, sn_n, w_b;
            and  g_sv  (w_step, A_next[i], step);
            or   g_ae  (any_e, rst, start_ok, step);
            not  g_an  (any_n, any_e);
            and  g_h   (w_hold, A[i], any_n);
            or   g_b   (w_b, w_step, w_hold);
            wire so_n; not g_son (so_n, start_ok);
            and  g_o   (A_reg_next[i], w_b, rst_n, so_n);
        end
    endgenerate

    // --- Q_reg (8 bits): rst->0, start_ok->Dividend, step->Q_next ---
    wire [7:0] Q_reg_next;
    generate
        for (i = 0; i < 8; i = i + 1) begin : qn
            wire w_so, w_step, w_hold, any_e2, any_n2, w_b2;
            and  g_so2 (w_so,   Dividend[i], start_ok);
            and  g_sv2 (w_step, Q_next[i],   step);
            or   g_ae2 (any_e2, rst, start_ok, step);
            not  g_an2 (any_n2, any_e2);
            and  g_h2  (w_hold, Q_reg[i], any_n2);
            or   g_b2  (w_b2, w_so, w_step, w_hold);
            and  g_o2  (Q_reg_next[i], w_b2, rst_n);
        end
    endgenerate

    // --- D_reg (8 bits): rst->0, start_ok->Divisor, else hold ---
    wire [7:0] D_reg_next;
    generate
        for (i = 0; i < 8; i = i + 1) begin : dn
            wire w_so, w_hold, any_e3, any_n3, w_b3;
            and  g_so3 (w_so,   Divisor[i], start_ok);
            or   g_ae3 (any_e3, rst, start_ok);
            not  g_an3 (any_n3, any_e3);
            and  g_h3  (w_hold, D_reg[i], any_n3);
            or   g_b3  (w_b3, w_so, w_hold);
            and  g_o3  (D_reg_next[i], w_b3, rst_n);
        end
    endgenerate

    // --- count (4 bits): rst->0, start_ok->8, step->count-1 ---
    wire [3:0] count_minus1;
    assign count_minus1 = count - 4'd1;
    wire [3:0] count_init = 4'b1000;
    wire [3:0] count_next;
    generate
        for (i = 0; i < 4; i = i + 1) begin : ctn
            wire w_so, w_step, w_hold, any_e4, any_n4, w_b4;
            and  g_so4 (w_so,   count_init[i],   start_ok);
            and  g_sv4 (w_step, count_minus1[i], step);
            or   g_ae4 (any_e4, rst, start_ok, step);
            not  g_an4 (any_n4, any_e4);
            and  g_h4  (w_hold, count[i], any_n4);
            or   g_b4  (w_b4, w_so, w_step, w_hold);
            and  g_o4  (count_next[i], w_b4, rst_n);
        end
    endgenerate

    // --- running: rst->0, start_ok->1, last_cycle->0, else hold ---
    wire any_run_e, any_run_n, w_run_hold, running_next;
    or   g_are  (any_run_e, rst, start_ok, cnt_is_1);
    not  g_arn  (any_run_n, any_run_e);
    and  g_rh   (w_run_hold, running, any_run_n);
    or   g_rb   (running_next, start_ok, w_run_hold);
    wire running_next_rst;
    and  g_rnr  (running_next_rst, running_next, rst_n);

    // --- done: rst->0, last_cycle->1, start_dbz->1, else->0 ---
    wire done_set, done_next;
    or   g_ds   (done_set, cnt_is_1, start_dbz);
    and  g_dn   (done_next, done_set, rst_n);

    // --- div_by_zero: rst->0, start_dbz->1, start_ok->0, else hold ---
    wire any_dbz_e, any_dbz_n, w_dbz_hold, dbz_next;
    or   g_adbe (any_dbz_e, rst, start_dbz, start_ok);
    not  g_adbn (any_dbz_n, any_dbz_e);
    and  g_dbzh (w_dbz_hold, dbz_r, any_dbz_n);
    or   g_dbzb (dbz_next, start_dbz, w_dbz_hold);
    wire dbz_next_rst;
    and  g_dbzr (dbz_next_rst, dbz_next, rst_n);

    // --- Quotient (8 bits): rst->0, last_cycle->Q_next, else hold ---
    wire [7:0] Quot_next;
    generate
        for (i = 0; i < 8; i = i + 1) begin : qoutn
            wire w_lc, w_hold, any_eq, any_nq, w_bq;
            and  g_lcq (w_lc,   Q_next[i],     cnt_is_1);
            or   g_aeq (any_eq, rst, cnt_is_1);
            not  g_anq (any_nq, any_eq);
            and  g_hq  (w_hold, Quotient_r[i], any_nq);
            or   g_bq  (w_bq, w_lc, w_hold);
            and  g_oq  (Quot_next[i], w_bq, rst_n);
        end
    endgenerate

    // --- Remainder (8 bits): rst->0, last_cycle->A_next, else hold ---
    wire [7:0] Rem_next;
    generate
        for (i = 0; i < 8; i = i + 1) begin : remn
            wire w_lc, w_hold, any_er, any_nr, w_br;
            and  g_lcr (w_lc,   A_next[i],      cnt_is_1);
            or   g_aer (any_er, rst, cnt_is_1);
            not  g_anr (any_nr, any_er);
            and  g_hr  (w_hold, Remainder_r[i], any_nr);
            or   g_br  (w_br, w_lc, w_hold);
            and  g_or  (Rem_next[i], w_br, rst_n);
        end
    endgenerate

    // -----------------------------------------------------------------------
    // DFF instantiation
    // -----------------------------------------------------------------------
    generate
        for (i = 0; i < 8; i = i+1) begin : dff_A       dff_posedge d(.clk(clk),.d(A_reg_next[i]),  .q(A[i]));        end
        for (i = 0; i < 8; i = i+1) begin : dff_Q       dff_posedge d(.clk(clk),.d(Q_reg_next[i]),  .q(Q_reg[i]));    end
        for (i = 0; i < 8; i = i+1) begin : dff_D       dff_posedge d(.clk(clk),.d(D_reg_next[i]),  .q(D_reg[i]));    end
        for (i = 0; i < 4; i = i+1) begin : dff_count   dff_posedge d(.clk(clk),.d(count_next[i]),  .q(count[i]));    end
        for (i = 0; i < 8; i = i+1) begin : dff_Quot    dff_posedge d(.clk(clk),.d(Quot_next[i]),   .q(Quotient_r[i])); end
        for (i = 0; i < 8; i = i+1) begin : dff_Rem     dff_posedge d(.clk(clk),.d(Rem_next[i]),    .q(Remainder_r[i])); end
    endgenerate
    dff_posedge dff_running (.clk(clk), .d(running_next_rst), .q(running));
    dff_posedge dff_done    (.clk(clk), .d(done_next),        .q(done_r));
    dff_posedge dff_dbz     (.clk(clk), .d(dbz_next_rst),     .q(dbz_r));

endmodule
