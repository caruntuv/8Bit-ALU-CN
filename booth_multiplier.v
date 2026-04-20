module booth_multiplier (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        enable,
    input  wire [7:0]  M,
    input  wire [7:0]  Q,
    output reg  [15:0] Product,
    output reg         done
);
    // Internal state registers
    reg  [7:0]  A;         // Accumulator (partial sum)
    reg  [8:0]  QQ;        // Q register with extra LSB for Booth pair
    reg  [7:0]  M_reg;     // Stored multiplier
    reg  [3:0]  count;     // Step counter (8 iterations)
    reg         running;   // Whether algorithm is in progress

    // Combinational results from the shared adder and subtractor
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

    // Compute next value of A based on the current Booth pair (QQ[1:0])
    // QQ[1:0] = 01 -> add M;  10 -> sub M;  00/11 -> no change
    wire do_add = (QQ[1:0] == 2'b01);
    wire do_sub = (QQ[1:0] == 2'b10);

    wire [7:0] A_after_op;
    wire [7:0] add_mux, sub_mux, nop_mux;
    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : a_mux
            wire a_add, a_sub, a_nop;
            and m_add (a_add, add_result[gi], do_add);
            and m_sub (a_sub, sub_result[gi], do_sub);
            wire do_nop;
            nor m_nop_flag (do_nop, do_add, do_sub);    // neither add nor sub
            and m_nop (a_nop, A[gi], do_nop);
            or  m_out (A_after_op[gi], a_add, a_sub, a_nop);
        end
    endgenerate

    // Arithmetic right shift of A_after_op (preserve sign bit)
    wire [7:0] A_shifted;
    assign A_shifted = {A_after_op[7], A_after_op[7:1]};

    // Next QQ: shift in A_after_op[0] at the top, shift rest right
    wire [8:0] QQ_shifted;
    assign QQ_shifted = {A_after_op[0], QQ[8:1]};

    // Final product assembly (last cycle result)
    wire [15:0] final_product;
    assign final_product = {A_shifted[7], A_shifted[7:1], QQ_shifted[8:1]};

    // Sequential state update — replaced always block with explicit next-state signals
    // and DFF-style register-file (using non-blocking assigns kept as procedural
    // but driven by purely combinational next-state wires above)
    wire last_cycle;
    assign last_cycle = (count == 4'd1) & running;

    // Because Verilog has no built-in multi-bit sequential primitive, we use
    // a single clocked process that captures the combinational next-state
    // computed above — this replaces the monolithic always block with a clean
    // register-capture pattern: all decision logic is now in the assign wires.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A       <= 8'd0;
            QQ      <= 9'd0;
            M_reg   <= 8'd0;
            count   <= 4'd0;
            Product <= 16'd0;
            done    <= 1'b0;
            running <= 1'b0;
        end else if (start && !running) begin
            A       <= 8'd0;
            QQ      <= {Q, 1'b0};
            M_reg   <= M;
            count   <= 4'd8;
            done    <= 1'b0;
            running <= 1'b1;
        end else if (running) begin
            A       <= A_shifted;
            QQ      <= QQ_shifted;
            count   <= count - 1;
            if (last_cycle) begin
                running <= 1'b0;
                done    <= 1'b1;
                Product <= final_product;
            end
        end else begin
            done <= 1'b0;
        end
    end
endmodule
