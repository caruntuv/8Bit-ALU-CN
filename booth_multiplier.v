// Booth radix-2 multiplier — fully structural.
// Every register is built from dff_posedge primitives.
// No always blocks anywhere in this module.
module booth_multiplier (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        enable,
    input  wire [7:0]  M,
    input  wire [7:0]  Q,
    output wire [15:0] Product,
    output wire        done
);
    // -----------------------------------------------------------------------
    // Registered state (all built from DFFs)
    // -----------------------------------------------------------------------
    wire [7:0]  A;        // accumulator
    wire [8:0]  QQ;       // Q shift register + extra LSB for Booth pair
    wire [7:0]  M_reg;    // latched multiplier
    wire [3:0]  count;    // step counter
    wire        running;  // 1 while algorithm is active
    wire [15:0] Product_r;// registered product
    wire        done_r;   // registered done flag

    assign Product = Product_r;
    assign done    = done_r;

    // -----------------------------------------------------------------------
    // Shared adder and subtractor (combinational)
    // -----------------------------------------------------------------------
    wire [7:0] add_result, sub_result;
    wire       add_cout,   sub_bout;

    adder_8bit adder (
        .A(A), .B(M_reg), .Cin(1'b0), .enable(1'b1),
        .Sum(add_result), .Cout(add_cout)
    );
    subtractor_8bit suber (
        .A(A), .B(M_reg), .enable(1'b1),
        .Diff(sub_result), .Bout(sub_bout)
    );

    // -----------------------------------------------------------------------
    // Booth operation select
    //   QQ[1:0] == 01 -> add    QQ[1:0] == 10 -> sub    else -> nop
    // -----------------------------------------------------------------------
    wire do_add, do_sub, do_nop;
    wire qq0_n, qq1_n;
    not g_qq0n (qq0_n, QQ[0]);
    not g_qq1n (qq1_n, QQ[1]);
    and g_add  (do_add, qq1_n, QQ[0]);   // !QQ[1] &  QQ[0]
    and g_sub  (do_sub, QQ[1], qq0_n);   //  QQ[1] & !QQ[0]
    nor g_nop  (do_nop, do_add, do_sub);

    // A after Booth operation (before shift)
    wire [7:0] A_op;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : op_mux
            wire w_add, w_sub, w_nop;
            and ga (w_add, add_result[i], do_add);
            and gs (w_sub, sub_result[i], do_sub);
            and gn (w_nop, A[i],          do_nop);
            or  go (A_op[i], w_add, w_sub, w_nop);
        end
    endgenerate

    // Arithmetic right-shift of A_op (sign-extend bit 7)
    wire [7:0] A_shifted;
    assign A_shifted = {A_op[7], A_op[7:1]};

    // QQ shift: bring A_op[0] into the top, shift rest right
    wire [8:0] QQ_shifted;
    assign QQ_shifted = {A_op[0], QQ[8:1]};

    // Final product (assembled in last cycle)
    wire [15:0] final_product;
    assign final_product = {A_shifted[7], A_shifted[7:1], QQ_shifted[8:1]};

    // -----------------------------------------------------------------------
    // Control conditions
    // -----------------------------------------------------------------------
    wire rst_n;
    not g_rstn (rst_n, rst);

    // last_cycle = running & (count == 1)
    wire cnt_is_1;
    wire c3n, c2n, c1n;
    not g_c3n (c3n, count[3]);
    not g_c2n (c2n, count[2]);
    not g_c1n (c1n, count[1]);
    and g_cnt1 (cnt_is_1, c3n, c2n, c1n, count[0], running); // 0001 & running

    // start_new = start & !running
    wire running_n, start_new;
    not g_rn (running_n, running);
    and g_sn (start_new, start, running_n);

    // step = running & !last_cycle
    wire step;
    wire cnt_is_1_n;
    not g_li (cnt_is_1_n, cnt_is_1);
    and g_step (step, running, cnt_is_1_n);

    // -----------------------------------------------------------------------
    // Next-state logic for every register
    // Three input cases: rst, start_new, step (mutually prioritised by mux chain)
    // -----------------------------------------------------------------------

    // Helper: 3-way mux per bit
    // out = rst ? rst_val : start_new ? sn_val : step ? step_val : hold_val
    // Implemented as priority mux: rst overrides start_new overrides step overrides hold

    // --- A (8 bits) ---
    // rst->0, start_new->0, step->A_shifted
    wire [7:0] A_next;
    generate
        for (i = 0; i < 8; i = i + 1) begin : a_next
            wire w_step_val, w_hold, w_base, sel_step_n;
            and  g_sv  (w_step_val, A_shifted[i], step);
            // hold = !rst & !start_new & !step  -> just A[i] when none active
            wire any_event;
            or   g_any (any_event, rst, start_new, step);
            wire any_n;
            not  g_an  (any_n, any_event);
            and  g_hld (w_hold, A[i], any_n);
            or   g_base(w_base, w_step_val, w_hold);
            // rst and start_new both force 0 -> just AND with rst_n & start_new_n
            wire sn_n;
            not  g_snn (sn_n, start_new);
            and  g_out (A_next[i], w_base, rst_n, sn_n);
        end
    endgenerate

    // --- QQ (9 bits) ---
    // rst->0, start_new->{Q,1'b0}, step->QQ_shifted
    wire [8:0] QQ_init;
    assign QQ_init = {Q, 1'b0};

    wire [8:0] QQ_next;
    generate
        for (i = 0; i < 9; i = i + 1) begin : qq_next
            wire w_sn, w_step_val, w_hold, any_event2, any_n2, sn_n2, w_base2;
            and  g_sn2  (w_sn,       QQ_init[i],  start_new);
            and  g_sv2  (w_step_val, QQ_shifted[i], step);
            or   g_any2 (any_event2, rst, start_new, step);
            not  g_an2  (any_n2, any_event2);
            and  g_hld2 (w_hold, QQ[i], any_n2);
            or   g_b2   (w_base2, w_sn, w_step_val, w_hold);
            and  g_o2   (QQ_next[i], w_base2, rst_n);
        end
    endgenerate

    // --- M_reg (8 bits) ---
    // rst->0, start_new->M, step->hold
    wire [7:0] M_reg_next;
    generate
        for (i = 0; i < 8; i = i + 1) begin : mreg_next
            wire w_sn, w_hold, any_event3, any_n3, sn_n3, w_base3;
            and  g_sn3  (w_sn,   M[i],     start_new);
            or   g_any3 (any_event3, rst, start_new);
            not  g_an3  (any_n3, any_event3);
            and  g_hld3 (w_hold, M_reg[i], any_n3);
            or   g_b3   (w_base3, w_sn, w_hold);
            and  g_o3   (M_reg_next[i], w_base3, rst_n);
        end
    endgenerate

    // --- count (4 bits) ---
    // rst->0, start_new->8 (4'b1000), step->count-1
    wire [3:0] count_minus1;
    assign count_minus1 = count - 4'd1;

    wire [3:0] count_init = 4'b1000;
    wire [3:0] count_next;
    generate
        for (i = 0; i < 4; i = i + 1) begin : cnt_next
            wire w_sn, w_step_val, w_hold, any_e4, any_n4, w_b4;
            and  g_sn4  (w_sn,       count_init[i], start_new);
            and  g_sv4  (w_step_val, count_minus1[i], step);
            or   g_any4 (any_e4, rst, start_new, step);
            not  g_an4  (any_n4, any_e4);
            and  g_hld4 (w_hold, count[i], any_n4);
            or   g_b4   (w_b4, w_sn, w_step_val, w_hold);
            and  g_o4   (count_next[i], w_b4, rst_n);
        end
    endgenerate

    // --- running (1 bit) ---
    // rst->0, start_new->1, last_cycle->0, else hold
    wire running_next;
    wire not_last_n;
    not  g_lc_n (not_last_n, cnt_is_1);  // last_cycle already encodes running
    wire any_run_event, any_run_n, w_run_hold;
    or   g_arune (any_run_event, rst, start_new, cnt_is_1);
    not  g_arunn (any_run_n, any_run_event);
    and  g_runh  (w_run_hold, running, any_run_n);
    or   g_runb  (running_next, start_new, w_run_hold); // start_new sets it; last_cycle+rst leave it 0
    wire running_next_rst;
    and  g_runnr (running_next_rst, running_next, rst_n);

    // --- done (1 bit) ---
    // rst->0, last_cycle->1, start_new->0, else->0
    wire done_next;
    and  g_done (done_next, cnt_is_1, rst_n);

    // --- Product (16 bits) ---
    // rst->0, last_cycle->final_product, else hold
    wire [15:0] Product_next;
    generate
        for (i = 0; i < 16; i = i + 1) begin : prod_next
            wire w_lc, w_hold, any_ep, any_np, w_bp;
            and  g_lcp (w_lc,   final_product[i], cnt_is_1);
            or   g_anyp (any_ep, rst, cnt_is_1);
            not  g_anp  (any_np, any_ep);
            and  g_hldp (w_hold, Product_r[i], any_np);
            or   g_bp   (w_bp, w_lc, w_hold);
            and  g_op   (Product_next[i], w_bp, rst_n);
        end
    endgenerate

    // -----------------------------------------------------------------------
    // DFF instantiation — one per bit of every register
    // -----------------------------------------------------------------------
    generate
        for (i = 0; i < 8;  i = i+1) begin : dff_A       dff_posedge d(.clk(clk),.d(A_next[i]),       .q(A[i]));       end
        for (i = 0; i < 9;  i = i+1) begin : dff_QQ      dff_posedge d(.clk(clk),.d(QQ_next[i]),      .q(QQ[i]));      end
        for (i = 0; i < 8;  i = i+1) begin : dff_M       dff_posedge d(.clk(clk),.d(M_reg_next[i]),   .q(M_reg[i]));   end
        for (i = 0; i < 4;  i = i+1) begin : dff_count   dff_posedge d(.clk(clk),.d(count_next[i]),   .q(count[i]));   end
        for (i = 0; i < 16; i = i+1) begin : dff_Product dff_posedge d(.clk(clk),.d(Product_next[i]), .q(Product_r[i])); end
    endgenerate
    dff_posedge dff_running (.clk(clk), .d(running_next_rst), .q(running));
    dff_posedge dff_done    (.clk(clk), .d(done_next),        .q(done_r));

endmodule
