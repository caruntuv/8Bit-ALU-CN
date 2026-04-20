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

```
reg [7:0]  A;        // Registru pentru rest parțial
reg [7:0]  Q_reg;    // Registru pentru cât (inițial conține deîmpărțitul)
reg [7:0]  D_reg;    // Registru pentru împărțitor
reg [3:0]  count;    // Contor (8 iterații)
reg        running;  // Indică dacă algoritmul rulează

// Scăzător
wire [7:0] sub_result;
wire       sub_bout;   // împrumut (borrow-out)

subtractor_8bit suber (
    .A(A), .B(D_reg), .enable(1'b1),
    .Diff(sub_result), .Bout(sub_bout)
);

// Fiecare iterație:
//   1. Se face shift la stânga pe A și se aduce MSB din Q_reg → A_shift
//   2. Se încearcă scăderea lui D_reg din A_shift
//   3. Dacă nu există împrumut (sub_bout=0): păstrăm rezultatul, bit cât = 1
//      Dacă există împrumut (sub_bout=1): restaurăm valoarea, bit cât = 0

// Pasul 1: shift la stânga pentru A
wire [7:0] A_shift;
assign A_shift = {A[6:0], Q_reg[7]};

// Scădere folosind A_shift
wire [7:0] sub_shift_result;
wire       sub_shift_bout;

subtractor_8bit suber_shift (
    .A(A_shift), .B(D_reg), .enable(1'b1),
    .Diff(sub_shift_result), .Bout(sub_shift_bout)
);

// Alegerea noului A
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

// Shift pentru Q
wire [7:0] Q_next;
assign Q_next = {Q_reg[6:0], q_bit};

// Detectare împărțire la zero
wire div_zero;
assign div_zero = (Divisor == 8'd0);

wire last_cycle;
assign last_cycle = (count == 4'd1) & running;

// Blocul Always (controlul secvențial)
always @(posedge clk or posedge rst) begin    //Deoarece scazatorul e un modul hardware simulat,
    if (rst) begin							  //in blocul de always, se schimba doar registrii, iar
        A           <= 8'd0;  				  //scazatorul e mereu activ, scazand.
        Q_reg       <= 8'd0;
        D_reg       <= 8'd0;
        count       <= 4'd0;
        Quotient    <= 8'd0; 				  //->daca rst e activ, se reseteaza registrii
        Remainder   <= 8'd0;
        done        <= 1'b0;
        running     <= 1'b0;
        div_by_zero <= 1'b0;

    end else if (start && !running) begin     //->inceperea operatiei de scadere.
        if (div_zero) begin                  //->verifica daca e impartire la 0, trateaza cazul
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
        count <= count - 1;                  //daca a inceput deja, aici continua

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
```

endmodule
