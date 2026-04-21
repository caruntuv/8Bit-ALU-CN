module alu_8bit (
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  op,
    input  wire        start,
    input  wire [7:0]  A_in,    
    input  wire [7:0]  B_in,    
    output wire [15:0] OUTBUS,  
    output wire        alu_done
);
    wire [7:0] INBUS_A;         
    wire [7:0] INBUS_B;         
    wire ra_load, rb_load, rc_load;
    wire ra_oe,   rb_oe,   rc_oe;
    wire add_en,  sub_en,  mul_start, div_start;
    wire mul_done, div_done;
    register_8bit RA (
        .clk(clk), .rst(rst),
        .load(ra_load), .oe(ra_oe),
        .D(A_in), .Q(INBUS_A)
    );
    register_8bit RB (
        .clk(clk), .rst(rst),
        .load(rb_load), .oe(rb_oe),
        .D(B_in), .Q(INBUS_B)
    );
    wire [7:0] rc_in_hi, rc_in_lo;
    wire [7:0] rc_q_hi, rc_q_lo;
    register_8bit RC_hi (
        .clk(clk), .rst(rst),
        .load(rc_load), .oe(rc_oe),
        .D(rc_in_hi), .Q(rc_q_hi)
    );
    register_8bit RC_lo (
        .clk(clk), .rst(rst),
        .load(rc_load), .oe(rc_oe),
        .D(rc_in_lo), .Q(rc_q_lo)
    );
    wire [7:0] add_sum;
    wire       add_cout;
    adder_8bit ADDER (
        .A(INBUS_A), .B(INBUS_B), .Cin(1'b0),
        .enable(add_en),
        .Sum(add_sum), .Cout(add_cout)
    );
    wire [7:0] sub_diff;
    wire       sub_bout;
    subtractor_8bit SUBER (
        .A(INBUS_A), .B(INBUS_B),
        .enable(sub_en),
        .Diff(sub_diff), .Bout(sub_bout)
    );
    wire [15:0] mul_product;
    booth_multiplier MUL (
        .clk(clk), .rst(rst),
        .start(mul_start), .enable(1'b1),
        .M(INBUS_A), .Q(INBUS_B),
        .Product(mul_product), .done(mul_done)
    );
    wire [7:0] div_quotient, div_remainder;
    wire       div_by_zero;
    restoring_divider DIV (
        .clk(clk), .rst(rst),
        .start(div_start), .enable(1'b1),
        .Dividend(INBUS_A), .Divisor(INBUS_B),
        .Quotient(div_quotient), .Remainder(div_remainder),
        .done(div_done), .div_by_zero(div_by_zero)
    );
    wire [7:0] add_to_rc_hi, add_to_rc_lo;
    wire [7:0] sub_to_rc_hi, sub_to_rc_lo;
    wire [7:0] mul_to_rc_hi, mul_to_rc_lo;
    wire [7:0] div_to_rc_hi, div_to_rc_lo;
    assign add_to_rc_hi = add_en ? {7'b0, add_cout} : 8'b0;
    assign add_to_rc_lo = add_en ? add_sum           : 8'b0;
    assign sub_to_rc_hi = sub_en ? {7'b0, sub_bout}  : 8'b0;
    assign sub_to_rc_lo = sub_en ? sub_diff           : 8'b0;
    assign mul_to_rc_hi = mul_done ? mul_product[15:8] : 8'b0;
    assign mul_to_rc_lo = mul_done ? mul_product[7:0]  : 8'b0;
    assign div_to_rc_hi = div_done ? div_quotient      : 8'b0;
    assign div_to_rc_lo = div_done ? div_remainder     : 8'b0;
    assign rc_in_hi = add_to_rc_hi | sub_to_rc_hi | mul_to_rc_hi | div_to_rc_hi;
    assign rc_in_lo = add_to_rc_lo | sub_to_rc_lo | mul_to_rc_lo | div_to_rc_lo;
    assign OUTBUS = rc_oe ? {rc_q_hi, rc_q_lo} : 16'bz;
    control_unit CU (
        .clk(clk), .rst(rst),
        .op(op), .start(start),
        .mul_done(mul_done), .div_done(div_done),
        .ra_load(ra_load), .rb_load(rb_load), .rc_load(rc_load),
        .ra_oe(ra_oe),     .rb_oe(rb_oe),     .rc_oe(rc_oe),
        .add_en(add_en),   .sub_en(sub_en),
        .mul_start(mul_start), .div_start(div_start),
        .alu_done(alu_done)
    );
endmodule
