module alu_8bit (
    input  wire        clk,        // ceas
    input  wire        rst,        // reset
    input  wire [1:0]  op,         // cod operatie
    input  wire        start,      // pornire
    input  wire [7:0]  A_in,       // operand a
    input  wire [7:0]  B_in,       // operand b
    output wire [15:0] OUTBUS,     // rezultat final
    output wire        alu_done    // operatie gata
);
    wire [7:0] INBUS_A; // bus intern a
    wire [7:0] INBUS_B; // bus intern b

    wire ra_load, rb_load, rc_load; // comenzi load
    wire ra_oe,   rb_oe,   rc_oe;   // comenzi iesire
    wire add_en,  sub_en,  mul_start, div_start; // comenzi operatii
    wire mul_done, div_done; // finalizari operatii lente

    register_8bit RA (
        .clk(clk), .rst(rst),
        .load(ra_load), .oe(ra_oe),
        .D(A_in), .Q(INBUS_A)
    ); // registru operand a

    register_8bit RB (
        .clk(clk), .rst(rst),
        .load(rb_load), .oe(rb_oe),
        .D(B_in), .Q(INBUS_B)
    ); // registru operand b

    wire [7:0] rc_in_hi, rc_in_lo; // intrari rezultat
    wire [7:0] rc_q_hi,  rc_q_lo;  // iesiri rezultat

    register_8bit RC_hi (
        .clk(clk), .rst(rst),
        .load(rc_load), .oe(rc_oe),
        .D(rc_in_hi), .Q(rc_q_hi)
    ); // registru rezultat sus

    register_8bit RC_lo (
        .clk(clk), .rst(rst),
        .load(rc_load), .oe(rc_oe),
        .D(rc_in_lo), .Q(rc_q_lo)
    ); // registru rezultat jos

    wire [7:0] add_sum; // suma
    wire       add_cout; // carry adunare

    adder_8bit ADDER (
        .A(INBUS_A), .B(INBUS_B), .Cin(1'b0),
        .enable(add_en),
        .Sum(add_sum), .Cout(add_cout)
    ); // modul adunare

    wire [7:0] sub_diff; // diferenta
    wire       sub_bout; // borrow scadere

    subtractor_8bit SUBER (
        .A(INBUS_A), .B(INBUS_B),
        .enable(sub_en),
        .Diff(sub_diff), .Bout(sub_bout)
    ); // modul scadere

    wire [15:0] mul_product; // produs inmultire

    booth_multiplier MUL (
        .clk(clk), .rst(rst),
        .start(mul_start), .enable(1'b1),
        .M(INBUS_A), .Q(INBUS_B),
        .Product(mul_product), .done(mul_done)
    ); // modul inmultire

    wire [7:0] div_quotient, div_remainder; // cat si rest
    wire       div_by_zero; // impartire la zero

    restoring_divider DIV (
        .clk(clk), .rst(rst),
        .start(div_start), .enable(1'b1),
        .Dividend(INBUS_A), .Divisor(INBUS_B),
        .Quotient(div_quotient), .Remainder(div_remainder),
        .done(div_done), .div_by_zero(div_by_zero)
    ); // modul impartire

    // pastreaza done inca un ciclu
    wire mul_done_held, div_done_held; // done intarziat

    dff_posedge dff_mul_hold (.clk(clk), .d(mul_done), .q(mul_done_held)); // hold mul done
    dff_posedge dff_div_hold (.clk(clk), .d(div_done), .q(div_done_held)); // hold div done

    // surse rezultat
    wire [7:0] add_to_rc_hi, add_to_rc_lo; // rezultat adunare
    wire [7:0] sub_to_rc_hi, sub_to_rc_lo; // rezultat scadere
    wire [7:0] mul_to_rc_hi, mul_to_rc_lo; // rezultat inmultire
    wire [7:0] div_to_rc_hi, div_to_rc_lo; // rezultat impartire

    assign add_to_rc_hi = add_en        ? {7'b0, add_cout}   : 8'b0; // carry sus
    assign add_to_rc_lo = add_en        ? add_sum             : 8'b0; // suma jos
    assign sub_to_rc_hi = sub_en        ? {7'b0, sub_bout}   : 8'b0; // borrow sus
    assign sub_to_rc_lo = sub_en        ? sub_diff            : 8'b0; // diferenta jos
    assign mul_to_rc_hi = mul_done_held ? mul_product[15:8]   : 8'b0; // produs sus
    assign mul_to_rc_lo = mul_done_held ? mul_product[7:0]    : 8'b0; // produs jos
    assign div_to_rc_hi = div_done_held ? div_quotient        : 8'b0; // cat sus
    assign div_to_rc_lo = div_done_held ? div_remainder       : 8'b0; // rest jos

    assign rc_in_hi = add_to_rc_hi | sub_to_rc_hi | mul_to_rc_hi | div_to_rc_hi; // rezultat sus ales
    assign rc_in_lo = add_to_rc_lo | sub_to_rc_lo | mul_to_rc_lo | div_to_rc_lo; // rezultat jos ales

    assign OUTBUS = rc_oe ? {rc_q_hi, rc_q_lo} : 16'bz; // iesire finala

    control_unit CU (
        .clk(clk), .rst(rst),
        .op(op), .start(start),
        .mul_done(mul_done), .div_done(div_done),
        .ra_load(ra_load), .rb_load(rb_load), .rc_load(rc_load),
        .ra_oe(ra_oe),     .rb_oe(rb_oe),     .rc_oe(rc_oe),
        .add_en(add_en),   .sub_en(sub_en),
        .mul_start(mul_start), .div_start(div_start),
        .alu_done(alu_done)
    ); // unitate control

endmodule