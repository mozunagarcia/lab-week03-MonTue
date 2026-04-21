//`include "src/debouncer.sv"

module top #(
    parameter int DEBOUNCE_THRESHOLD = 500_000
) (
    input  logic clk,
    input  logic btn1,         // PMOD4 C4
    input  logic btn2,         // PMOD4 C3
    input  logic [3:0] sw,     // PMOD4 H3/J3/J2/K3 = sw[0..3]
    output logic [6:0] seg,    // PMOD5 a-g  (seg[0]=a ... seg[6]=g)
    output logic dp,           // PMOD5 D9
    output logic led_r,        // on-board RGB: red   B11 (active-low)
    output logic led_g,        // on-board RGB: green A11 (active-low)
    output logic led_b         // on-board RGB: blue  A12 (active-low)
);

    logic btn1_debounced;

    debouncer #(.THRESHOLD(DEBOUNCE_THRESHOLD)) deb_inst (
        .clk(clk),
        .btn_raw(btn1),
        .btn_clean(btn1_debounced)
    );

    typedef enum logic [1:0] { OFF_IDLE = 2'b00,
                                ON_IDLE = 2'b01,
                                OFF_PRESS = 2'b10,
                                ON_PRESS = 2'b11 } state_t;

    state_t state = OFF_IDLE;
    state_t next_state;

    always_ff @(posedge clk) begin
        state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            OFF_IDLE:  next_state = state_t'(btn1_debounced ? OFF_PRESS : OFF_IDLE);
            OFF_PRESS: next_state = state_t'(btn1_debounced ? OFF_PRESS : ON_IDLE);
            ON_IDLE:   next_state = state_t'(btn1_debounced ? ON_PRESS  : ON_IDLE);
            ON_PRESS:  next_state = state_t'(btn1_debounced ? ON_PRESS  : OFF_IDLE);
            default: next_state = OFF_IDLE;
        endcase
    end

    always_comb begin
        led_r = 1'b0;
        led_b = 1'b0;
        case (state)
            ON_IDLE, ON_PRESS: led_g = 1'b1; 
            default: led_g = 1'b0;
        endcase
    end

    // seg active-high (adjust polarity for common-anode displays)
    always_comb begin
        dp = 1'b0;
        case (state)
            ON_IDLE, ON_PRESS: seg = 7'b111_1111; // all segments on
            default: seg = 7'b000_0000; // all segments off
        endcase
    end

endmodule
