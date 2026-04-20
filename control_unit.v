module control_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  op,
    input  wire        start,
    input  wire        mul_done,
    input  wire        div_done,
    output reg         ra_load,
    output reg         rb_load,
    output reg         rc_load,
    output reg         ra_oe,
    output reg         rb_oe,
    output reg         rc_oe,
    output reg         add_en,
    output reg         sub_en,
    output reg         mul_start,
    output reg         div_start,
    output reg         alu_done
);
    localparam S_IDLE  = 3'd0;
    localparam S_LOAD  = 3'd1;
    localparam S_EXEC  = 3'd2;
    localparam S_WAIT  = 3'd3;
    localparam S_STORE = 3'd4;
    localparam S_DONE  = 3'd5;

    reg [2:0] state;

    // -----------------------------------------------------------------------
    // Next-state logic: purely combinational, expressed with assign statements
    // -----------------------------------------------------------------------

    // Condition signals
    wire is_add   = (op == 2'b00);
    wire is_sub   = (op == 2'b01);
    wire is_mul   = (op == 2'b10);
    wire is_div   = (op == 2'b11);
    wire fast_op  = is_add | is_sub;                   // add/sub finish in one cycle
    wire wait_done = (is_mul & mul_done) | (is_div & div_done);

    wire [2:0] next_state;

    // Encode next state using combinational mux logic
    // From S_IDLE: go to S_LOAD when start=1, else stay
    wire [2:0] from_idle  = start       ? S_LOAD  : S_IDLE;
    // From S_LOAD: always go to S_EXEC
    wire [2:0] from_load  = S_EXEC;
    // From S_EXEC: fast ops go to S_STORE, slow ops go to S_WAIT
    wire [2:0] from_exec  = fast_op     ? S_STORE : S_WAIT;
    // From S_WAIT: go to S_STORE when mul/div signals done
    wire [2:0] from_wait  = wait_done   ? S_STORE : S_WAIT;
    // From S_STORE: always go to S_DONE
    wire [2:0] from_store = S_DONE;
    // From S_DONE: always go to S_IDLE
    wire [2:0] from_done  = S_IDLE;

    // Select the correct next-state based on current state
    assign next_state =
        (state == S_IDLE)  ? from_idle  :
        (state == S_LOAD)  ? from_load  :
        (state == S_EXEC)  ? from_exec  :
        (state == S_WAIT)  ? from_wait  :
        (state == S_STORE) ? from_store :
        (state == S_DONE)  ? from_done  :
                             S_IDLE;

    // -----------------------------------------------------------------------
    // State register: the only sequential element
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) state <= S_IDLE;
        else     state <= next_state;
    end

    // -----------------------------------------------------------------------
    // Output logic: purely combinational, expressed with assign statements
    // Each control signal is 1 only in the specific state(s) that need it
    // -----------------------------------------------------------------------

    wire in_load  = (state == S_LOAD);
    wire in_exec  = (state == S_EXEC);
    wire in_wait  = (state == S_WAIT);
    wire in_store = (state == S_STORE);
    wire in_done  = (state == S_DONE);

    // Outputs driven by assign (replaces the second always @(*) block)
    always @(*) begin
        ra_load   = in_load;
        rb_load   = in_load;
        rc_load   = in_store;
        ra_oe     = in_exec | in_wait;
        rb_oe     = in_exec | in_wait;
        rc_oe     = in_store | in_done;
        add_en    = in_exec & is_add;
        sub_en    = in_exec & is_sub;
        mul_start = in_exec & is_mul;
        div_start = in_exec & is_div;
        alu_done  = in_done;
    end
endmodule
