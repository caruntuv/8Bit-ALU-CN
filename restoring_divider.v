module restoring_divider (
    input  wire        clk,        // ceas
    input  wire        rst,        // reset
    input  wire        start,      // pornire
    input  wire        enable,     // enable extern
    input  wire [7:0]  Dividend,   // deimpartit
    input  wire [7:0]  Divisor,    // impartitor
    output wire [7:0]  Quotient,   // cat
    output wire [7:0]  Remainder,  // rest
    output wire        done,       // finalizare
    output wire        div_by_zero // impartire la zero
);
    wire [7:0] A;          // rest partial
    wire [7:0] Q_reg;      // cat in lucru
    wire [7:0] D_reg;      // impartitor memorat
    wire [3:0] count;      // contor pasi
    wire       running;    // operatie activa
    wire [7:0] Quotient_r; // cat memorat
    wire [7:0] Remainder_r;// rest memorat
    wire       done_r;     // done memorat
    wire       dbz_r;      // zero memorat

    assign Quotient    = Quotient_r;    // iesire cat
    assign Remainder   = Remainder_r;   // iesire rest
    assign done        = done_r;        // iesire done
    assign div_by_zero = dbz_r;         // iesire eroare

    wire [7:0] A_shift;                 // rest shiftat
    assign A_shift = {A[6:0], Q_reg[7]}; // shift stanga

    wire [7:0] sub_result; // rezultat scadere
    wire       sub_bout;   // borrow scadere

    subtractor_8bit suber (
        .A(A_shift), .B(D_reg), .enable(1'b1),
        .Diff(sub_result), .Bout(sub_bout)
    ); // incearca a_shift - d

    wire no_borrow;              // scadere valida
    not g_nb (no_borrow, sub_bout); // fara borrow

    wire [7:0] A_next; // urmatorul rest

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : a_mux
            wire w_keep, w_restore; // selectie rest
            and g_k (w_keep,    sub_result[i], no_borrow); // pastreaza scaderea
            and g_r (w_restore, A_shift[i],    sub_bout);  // restaureaza
            or  g_o (A_next[i], w_keep, w_restore);        // rest ales
        end
    endgenerate

    wire [7:0] Q_next;                 // urmatorul cat
    assign Q_next = {Q_reg[6:0], no_borrow}; // shift + bit cat

    wire rst_n;              // reset negat
    not g_rstn (rst_n, rst); // not reset

    wire div_zero; // divizor zero
    nor g_dz (div_zero, Divisor[0], Divisor[1], Divisor[2], Divisor[3],
                        Divisor[4], Divisor[5], Divisor[6], Divisor[7]);

    wire running_n, start_new;      // control start
    not g_rn (running_n, running);  // nu ruleaza
    and g_sn (start_new, start, running_n); // start nou

    wire div_zero_n, start_ok;       // start valid
    not g_dzn (div_zero_n, div_zero); // nu e zero
    and g_sok (start_ok, start_new, div_zero_n); // pornire valida

    wire start_dbz;                 // start cu zero
    and g_sdbz (start_dbz, start_new, div_zero); // eroare zero

    wire c3n, c2n, c1n, cnt_is_1; // ultim ciclu
    not g_c3n (c3n, count[3]);
    not g_c2n (c2n, count[2]);
    not g_c1n (c1n, count[1]);
    and g_lc  (cnt_is_1, c3n, c2n, c1n, count[0], running);

    wire step, cnt_is_1_n;        // pas normal
    not  g_lcn  (cnt_is_1_n, cnt_is_1);
    and  g_step (step, running, cnt_is_1_n);

    wire [7:0] A_reg_next; // urmatorul registru a
    generate
        for (i = 0; i < 8; i = i + 1) begin : an
            wire w_step, w_hold, any_e, any_n, sn_n, w_b; // mux a
            and  g_sv  (w_step, A_next[i], step); // valoare pas
            or   g_ae  (any_e, rst, start_ok, step); // eveniment
            not  g_an  (any_n, any_e); // fara eveniment
            and  g_h   (w_hold, A[i], any_n); // pastreaza
            or   g_b   (w_b, w_step, w_hold); // baza
            wire so_n; not g_son (so_n, start_ok); // start negat
            and  g_o   (A_reg_next[i], w_b, rst_n, so_n); // iesire a
        end
    endgenerate

    wire [7:0] Q_reg_next; // urmatorul registru q
    generate
        for (i = 0; i < 8; i = i + 1) begin : qn
            wire w_so, w_step, w_hold, any_e2, any_n2, w_b2; // mux q
            and  g_so2 (w_so,   Dividend[i], start_ok); // incarca dividend
            and  g_sv2 (w_step, Q_next[i],   step);     // pas impartire
            or   g_ae2 (any_e2, rst, start_ok, step);   // eveniment
            not  g_an2 (any_n2, any_e2);                // fara eveniment
            and  g_h2  (w_hold, Q_reg[i], any_n2);      // pastreaza
            or   g_b2  (w_b2, w_so, w_step, w_hold);    // baza
            and  g_o2  (Q_reg_next[i], w_b2, rst_n);    // iesire q
        end
    endgenerate

    wire [7:0] D_reg_next; // urmatorul divizor
    generate
        for (i = 0; i < 8; i = i + 1) begin : dn
            wire w_so, w_hold, any_e3, any_n3, w_b3; // mux d
            and  g_so3 (w_so,   Divisor[i], start_ok); // incarca divizor
            or   g_ae3 (any_e3, rst, start_ok);        // eveniment
            not  g_an3 (any_n3, any_e3);               // fara eveniment
            and  g_h3  (w_hold, D_reg[i], any_n3);     // pastreaza
            or   g_b3  (w_b3, w_so, w_hold);           // baza
            and  g_o3  (D_reg_next[i], w_b3, rst_n);   // iesire d
        end
    endgenerate

    wire [3:0] count_minus1;       // contor minus 1
    assign count_minus1 = count - 4'd1;

    wire [3:0] count_init = 4'b1000; // 8 pasi
    wire [3:0] count_next;           // urmator contor

    generate
        for (i = 0; i < 4; i = i + 1) begin : ctn
            wire w_so, w_step, w_hold, any_e4, any_n4, w_b4; // mux contor
            and  g_so4 (w_so,   count_init[i],   start_ok); // incarca 8
            and  g_sv4 (w_step, count_minus1[i], step);     // scade 1
            or   g_ae4 (any_e4, rst, start_ok, step);       // eveniment
            not  g_an4 (any_n4, any_e4);                    // fara eveniment
            and  g_h4  (w_hold, count[i], any_n4);          // pastreaza
            or   g_b4  (w_b4, w_so, w_step, w_hold);        // baza
            and  g_o4  (count_next[i], w_b4, rst_n);        // iesire contor
        end
    endgenerate

    wire any_run_e, any_run_n, w_run_hold, running_next; // control running
    or   g_are  (any_run_e, rst, start_ok, cnt_is_1); // eveniment running
    not  g_arn  (any_run_n, any_run_e);               // fara eveniment
    and  g_rh   (w_run_hold, running, any_run_n);     // pastreaza
    or   g_rb   (running_next, start_ok, w_run_hold);  // urmator running

    wire running_next_rst; // running cu reset
    and  g_rnr  (running_next_rst, running_next, rst_n);

    wire done_set, done_next; // control done
    or   g_ds   (done_set, cnt_is_1, start_dbz); // final sau eroare
    and  g_dn   (done_next, done_set, rst_n);    // done cu reset

    wire any_dbz_e, any_dbz_n, w_dbz_hold, dbz_next; // control zero
    or   g_adbe (any_dbz_e, rst, start_dbz, start_ok); // eveniment zero
    not  g_adbn (any_dbz_n, any_dbz_e);                // fara eveniment
    and  g_dbzh (w_dbz_hold, dbz_r, any_dbz_n);        // pastreaza
    or   g_dbzb (dbz_next, start_dbz, w_dbz_hold);      // urmator zero

    wire dbz_next_rst; // zero cu reset
    and  g_dbzr (dbz_next_rst, dbz_next, rst_n);

    wire [7:0] Quot_next; // urmator cat final
    generate
        for (i = 0; i < 8; i = i + 1) begin : qoutn
            wire w_lc, w_hold, any_eq, any_nq, w_bq; // mux cat final
            and  g_lcq (w_lc,   Q_next[i],     cnt_is_1); // salveaza cat
            or   g_aeq (any_eq, rst, cnt_is_1);           // eveniment
            not  g_anq (any_nq, any_eq);                  // fara eveniment
            and  g_hq  (w_hold, Quotient_r[i], any_nq);   // pastreaza
            or   g_bq  (w_bq, w_lc, w_hold);              // baza
            and  g_oq  (Quot_next[i], w_bq, rst_n);       // iesire cat
        end
    endgenerate

    wire [7:0] Rem_next; // urmator rest final
    generate
        for (i = 0; i < 8; i = i + 1) begin : remn
            wire w_lc, w_hold, any_er, any_nr, w_br; // mux rest final
            and  g_lcr (w_lc,   A_next[i],      cnt_is_1); // salveaza rest
            or   g_aer (any_er, rst, cnt_is_1);            // eveniment
            not  g_anr (any_nr, any_er);                   // fara eveniment
            and  g_hr  (w_hold, Remainder_r[i], any_nr);   // pastreaza
            or   g_br  (w_br, w_lc, w_hold);               // baza
            and  g_or  (Rem_next[i], w_br, rst_n);         // iesire rest
        end
    endgenerate

    generate
        for (i = 0; i < 8; i = i+1) begin : dff_A
            dff_posedge d(.clk(clk),.d(A_reg_next[i]),.q(A[i]));
        end // dff rest partial

        for (i = 0; i < 8; i = i+1) begin : dff_Q
            dff_posedge d(.clk(clk),.d(Q_reg_next[i]),.q(Q_reg[i]));
        end // dff q

        for (i = 0; i < 8; i = i+1) begin : dff_D
            dff_posedge d(.clk(clk),.d(D_reg_next[i]),.q(D_reg[i]));
        end // dff divizor

        for (i = 0; i < 4; i = i+1) begin : dff_count
            dff_posedge d(.clk(clk),.d(count_next[i]),.q(count[i]));
        end // dff contor

        for (i = 0; i < 8; i = i+1) begin : dff_Quot
            dff_posedge d(.clk(clk),.d(Quot_next[i]),.q(Quotient_r[i]));
        end // dff cat

        for (i = 0; i < 8; i = i+1) begin : dff_Rem
            dff_posedge d(.clk(clk),.d(Rem_next[i]),.q(Remainder_r[i]));
        end // dff rest
    endgenerate

    dff_posedge dff_running (.clk(clk), .d(running_next_rst), .q(running)); // dff running
    dff_posedge dff_done    (.clk(clk), .d(done_next),        .q(done_r));  // dff done
    dff_posedge dff_dbz     (.clk(clk), .d(dbz_next_rst),     .q(dbz_r));   // dff zero

endmodule
