module restoring_divider (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        enable,
    input  wire [7:0]  Dividend,
    input  wire [7:0]  Divisor,
    output reg  [7:0]  Quotient,
    output reg  [7:0]  Remainder,
    output reg         done,
    output reg         div_by_zero
);
    reg [7:0]  A;        // Partial remainder accumulator
    reg [7:0]  Q_reg;    // Dividend / quotient shift register
    reg [7:0]  D_reg;    // Stored divisor
    reg [3:0]  count;    // Step counter (8 iterations)
    reg        running;  // Whether algorithm is in progress

    // Subtractor: try A - D_reg each step
    wire [7:0] sub_result;
    wire       sub_bout;   // borrow-out: 1 means subtraction underflowed (A < D_reg)

    subtractor_8bit suber (
        .A(A), .B(D_reg), .enable(1'b1),
        .Diff(sub_result), .Bout(sub_bout)
    );

    // Each iteration:
    //   1. Shift A left by 1, bring in MSB of Q_reg  -> new_A_shift
    //   2. Try subtracting D_reg from new_A_shift
    //   3. If no borrow (sub_bout=0): subtraction succeeded -> keep result, quotient bit = 1
    //      If borrow    (sub_bout=1): restore old value      -> discard result, quotient bit = 0

    // Step 1: shift A left, bring in Q_reg[7]
    wire [7:0] A_shift;
    assign A_shift = {A[6:0], Q_reg[7]};

    // The subtractor uses A (the current register value), but we need it to act on A_shift.
    // We forward A_shift into the subtractor by wiring it combinationally:
    // (subtractor above already uses reg A; we update A before subtractor sees it via
    //  sequential logic — the net effect is equivalent to computing sub on A_shift)
    // To avoid re-wiring, we compute the shift-then-subtract combinationally:
    wire [7:0] sub_shift_result;
    wire       sub_shift_bout;
    subtractor_8bit suber_shift (
        .A(A_shift), .B(D_reg), .enable(1'b1),
        .Diff(sub_shift_result), .Bout(sub_shift_bout)
    );

    // Step 3: pick next A based on whether subtraction succeeded
    // If sub_shift_bout=0 (no borrow): A_next = sub_shift_result, q_bit = 1
    // If sub_shift_bout=1 (borrow):    A_next = A_shift (restore),  q_bit = 0
    wire [7:0] A_next;
    wire       q_bit;
    wire       no_borrow;

    not g_nb (no_borrow, sub_shift_bout);
    assign q_bit = no_borrow;

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : a_next_mux
            wire keep, restore;
            and g_keep    (keep,    sub_shift_result[gi], no_borrow);
            and g_restore (restore, A_shift[gi],          sub_shift_bout);
            or  g_out     (A_next[gi], keep, restore);
        end
    endgenerate

    // Q_reg shifts left by 1 each step; new LSB is the quotient bit
    wire [7:0] Q_next;
    assign Q_next = {Q_reg[6:0], q_bit};

    // Detect divide-by-zero before starting
    wire div_zero;
    assign div_zero = (Divisor == 8'd0);

    wire last_cycle;
    assign last_cycle = (count == 4'd1) & running;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A          <= 8'd0;
            Q_reg      <= 8'd0;
            D_reg      <= 8'd0;
            count      <= 4'd0;
            Quotient   <= 8'd0;
            Remainder  <= 8'd0;
            done       <= 1'b0;
            running    <= 1'b0;
            div_by_zero <= 1'b0;
        end else if (start && !running) begin
            if (div_zero) begin
                div_by_zero <= 1'b1;
                done        <= 1'b1;
            end else begin
                A           <= 8'd0;
                Q_reg       <= Dividend;
                D_reg       <= Divisor;
                count       <= 4'd8;
                done        <= 1'b0;
                running     <= 1'b1;
                div_by_zero <= 1'b0;
            end
        end else if (running) begin
            A     <= A_next;
            Q_reg <= Q_next;
            count <= count - 1;
            if (last_cycle) begin
                running   <= 1'b0;
                done      <= 1'b1;
                Quotient  <= Q_next;
                Remainder <= A_next;
            end
        end else begin
            done <= 1'b0;
        end
    end
endmodule
