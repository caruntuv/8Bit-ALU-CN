module booth_multiplier (
    input  wire        clk,      // ceas
    input  wire        rst,      // reset
    input  wire        start,    // pornire
    input  wire        enable,   // enable extern
    input  wire [7:0]  M,        // inmultitor
    input  wire [7:0]  Q,        // deinmultit
    output wire [15:0] Product,  // produs final
    output wire        done      // finalizare
);
    wire [7:0]  A;         // acumulator
    wire [8:0]  QQ;        // q plus bit extra
    wire [7:0]  M_reg;     // m memorat
    wire [3:0]  count;     // contor pasi
    wire        running;   // operatie activa
    wire [15:0] Product_r; // produs memorat
    wire        done_r;    // done memorat

    assign Product = Product_r; // iesire produs
    assign done    = done_r;    // iesire done

    wire [7:0] add_result, sub_result; // rezultate operatie
    wire       add_cout,   sub_bout;   // carry si borrow

    adder_8bit adder (
        .A(A), .B(M_reg), .Cin(1'b0), .enable(1'b1),
        .Sum(add_result), .Cout(add_cout)
    ); // aduna a cu m

    subtractor_8bit suber (
        .A(A), .B(M_reg), .enable(1'b1),
        .Diff(sub_result), .Bout(sub_bout)
    ); // scade m din a

    wire do_add, do_sub, do_nop; // comenzi booth
    wire qq0_n, qq1_n;           // biti negati

    not g_qq0n (qq0_n, QQ[0]);   // not qq0
    not g_qq1n (qq1_n, QQ[1]);   // not qq1
    and g_add  (do_add, qq1_n, QQ[0]); // caz 01
    and g_sub  (do_sub, QQ[1], qq0_n); // caz 10
    nor g_nop  (do_nop, do_add, do_sub); // caz 00 sau 11

    wire [7:0] A_op; // a dupa operatie

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : op_mux
            wire w_add, w_sub, w_nop; // selectii operatie
            and ga (w_add, add_result[i], do_add); // a+m
            and gs (w_sub, sub_result[i], do_sub); // a-m
            and gn (w_nop, A[i],          do_nop); // pastreaza a
            or  go (A_op[i], w_add, w_sub, w_nop); // rezultat ales
        end
    endgenerate

    wire [7:0] A_shifted; // a deplasat
    assign A_shifted = {A_op[7], A_op[7:1]}; // shift aritmetic dreapta

    wire [8:0] QQ_shifted; // qq deplasat
    assign QQ_shifted = {A_op[0], QQ[8:1]}; // intra bit din a

    wire [15:0] final_product; // produs final
    assign final_product = {A_shifted[7], A_shifted[7:1], QQ_shifted[8:1]}; // lipire rezultat

    wire rst_n; // reset negat
    not g_rstn (rst_n, rst); // not reset

    wire cnt_is_1; // ultimul pas
    wire c3n, c2n, c1n; // biti contor negati

    not g_c3n (c3n, count[3]); // not bit 3
    not g_c2n (c2n, count[2]); // not bit 2
    not g_c1n (c1n, count[1]); // not bit 1
    and g_cnt1 (cnt_is_1, c3n, c2n, c1n, count[0], running); // count este 1

    wire running_n, start_new; // pornire noua
    not g_rn (running_n, running); // not running
    and g_sn (start_new, start, running_n); // start daca nu ruleaza

    wire step; // pas normal
    wire cnt_is_1_n; // nu e ultimul pas
    not g_li (cnt_is_1_n, cnt_is_1); // not ultim pas
    and g_step (step, running, cnt_is_1_n); // ruleaza si nu e final

    wire [7:0] A_next; // urmatorul a

    generate
        for (i = 0; i < 8; i = i + 1) begin : a_next
            wire w_step_val, w_hold, w_base, sel_step_n; // semnale mux
            and  g_sv  (w_step_val, A_shifted[i], step); // valoare la pas
            wire any_event; // eveniment activ
            or   g_any (any_event, rst, start_new, step); // reset/start/step
            wire any_n; // niciun eveniment
            not  g_an  (any_n, any_event); // not eveniment
            and  g_hld (w_hold, A[i], any_n); // pastreaza a
            or   g_base(w_base, w_step_val, w_hold); // baza mux
            wire sn_n; // start negat
            not  g_snn (sn_n, start_new); // not start
            and  g_out (A_next[i], w_base, rst_n, sn_n); // iesire a_next
        end
    endgenerate

    wire [8:0] QQ_init; // qq initial
    assign QQ_init = {Q, 1'b0}; // q cu zero extra

    wire [8:0] QQ_next; // urmatorul qq

    generate
        for (i = 0; i < 9; i = i + 1) begin : qq_next
            wire w_sn, w_step_val, w_hold, any_event2, any_n2, sn_n2, w_base2; // semnale mux
            and  g_sn2  (w_sn,       QQ_init[i],  start_new); // incarcare q
            and  g_sv2  (w_step_val, QQ_shifted[i], step); // shift q
            or   g_any2 (any_event2, rst, start_new, step); // eveniment activ
            not  g_an2  (any_n2, any_event2); // niciun eveniment
            and  g_hld2 (w_hold, QQ[i], any_n2); // pastreaza qq
            or   g_b2   (w_base2, w_sn, w_step_val, w_hold); // baza mux
            and  g_o2   (QQ_next[i], w_base2, rst_n); // iesire qq_next
        end
    endgenerate

    wire [7:0] M_reg_next; // urmatorul m

    generate
        for (i = 0; i < 8; i = i + 1) begin : mreg_next
            wire w_sn, w_hold, any_event3, any_n3, sn_n3, w_base3; // semnale mux
            and  g_sn3  (w_sn,   M[i],     start_new); // incarcare m
            or   g_any3 (any_event3, rst, start_new); // reset sau start
            not  g_an3  (any_n3, any_event3); // niciun eveniment
            and  g_hld3 (w_hold, M_reg[i], any_n3); // pastreaza m
            or   g_b3   (w_base3, w_sn, w_hold); // baza mux
            and  g_o3   (M_reg_next[i], w_base3, rst_n); // iesire m_next
        end
    endgenerate

    wire [3:0] count_minus1; // contor minus 1
    assign count_minus1 = count - 4'd1; // decrementare

    wire [3:0] count_init = 4'b1000; // 8 pasi
    wire [3:0] count_next; // urmatorul contor

    generate
        for (i = 0; i < 4; i = i + 1) begin : cnt_next
            wire w_sn, w_step_val, w_hold, any_e4, any_n4, w_b4; // semnale mux
            and  g_sn4  (w_sn,       count_init[i], start_new); // incarcare 8
            and  g_sv4  (w_step_val, count_minus1[i], step); // scade contor
            or   g_any4 (any_e4, rst, start_new, step); // eveniment activ
            not  g_an4  (any_n4, any_e4); // niciun eveniment
            and  g_hld4 (w_hold, count[i], any_n4); // pastreaza contor
            or   g_b4   (w_b4, w_sn, w_step_val, w_hold); // baza mux
            and  g_o4   (count_next[i], w_b4, rst_n); // iesire contor
        end
    endgenerate

    wire running_next; // urmator running
    wire not_last_n; // semnal nefolosit
    not  g_lc_n (not_last_n, cnt_is_1); // not ultim pas

    wire any_run_event, any_run_n, w_run_hold; // control running
    or   g_arune (any_run_event, rst, start_new, cnt_is_1); // eveniment running
    not  g_arunn (any_run_n, any_run_event); // niciun eveniment
    and  g_runh  (w_run_hold, running, any_run_n); // pastreaza running
    or   g_runb  (running_next, start_new, w_run_hold); // setare running

    wire running_next_rst; // running dupa reset
    and  g_runnr (running_next_rst, running_next, rst_n); // reset running

    wire done_next; // urmator done
    and  g_done (done_next, cnt_is_1, rst_n); // done la final

    wire [15:0] Product_next; // urmator produs

    generate
        for (i = 0; i < 16; i = i + 1) begin : prod_next
            wire w_lc, w_hold, any_ep, any_np, w_bp; // semnale produs
            and  g_lcp (w_lc,   final_product[i], cnt_is_1); // produs final
            or   g_anyp (any_ep, rst, cnt_is_1); // reset sau final
            not  g_anp  (any_np, any_ep); // niciun eveniment
            and  g_hldp (w_hold, Product_r[i], any_np); // pastreaza produs
            or   g_bp   (w_bp, w_lc, w_hold); // baza mux
            and  g_op   (Product_next[i], w_bp, rst_n); // iesire produs
        end
    endgenerate

    generate
        for (i = 0; i < 8;  i = i+1) begin : dff_A       dff_posedge d(.clk(clk),.d(A_next[i]),       .q(A[i]));       end // dff a
        for (i = 0; i < 9;  i = i+1) begin : dff_QQ      dff_posedge d(.clk(clk),.d(QQ_next[i]),      .q(QQ[i]));      end // dff qq
        for (i = 0; i < 8;  i = i+1) begin : dff_M       dff_posedge d(.clk(clk),.d(M_reg_next[i]),   .q(M_reg[i]));   end // dff m
        for (i = 0; i < 4;  i = i+1) begin : dff_count   dff_posedge d(.clk(clk),.d(count_next[i]),   .q(count[i]));   end // dff contor
        for (i = 0; i < 16; i = i+1) begin : dff_Product dff_posedge d(.clk(clk),.d(Product_next[i]), .q(Product_r[i])); end // dff produs
    endgenerate

    dff_posedge dff_running (.clk(clk), .d(running_next_rst), .q(running)); // dff running
    dff_posedge dff_done    (.clk(clk), .d(done_next),        .q(done_r));  // dff done

endmodule