//`include "src/debouncer.sv"

module top #(
    parameter int DEBOUNCE_THRESHOLD = 500_000
) (
    input logic clk,
    input logic btn,
    output logic led
);

    logic btn_debounced;

    // Instantiate debouncer
    debouncer #(.THRESHOLD(DEBOUNCE_THRESHOLD)) deb_inst (
        .clk(clk),
        .btn_raw(btn),
        .btn_clean(btn_debounced)
    );

    typedef enum logic [1:0] { OFF_IDLE = 2'b00,
                                ON_IDLE = 2'b01,
                                OFF_PRESS = 2'b10,
                                ON_PRESS = 2'b11} state_t;

    state_t state = OFF_IDLE;
    state_t next_state;

    always_ff @(posedge clk) begin
        state <= next_state;
    end

    always_comb begin
        next_state = state; // default: hold current state
        case (state)
            OFF_IDLE: next_state = state_t'(btn_debounced ? OFF_PRESS : OFF_IDLE);
            OFF_PRESS: next_state = state_t'(btn_debounced ? OFF_PRESS : ON_IDLE);
            ON_IDLE: next_state = state_t'(btn_debounced ? ON_PRESS  : ON_IDLE);
            ON_PRESS: next_state = state_t'(btn_debounced ? ON_PRESS  : OFF_IDLE);
            default: next_state = OFF_IDLE;
        endcase
    end

    always_comb begin
        case (state)
            OFF_IDLE: led = 1'b0;
            OFF_PRESS: led = 1'b0;
            ON_IDLE: led = 1'b1;
            ON_PRESS: led = 1'b1;
            default: led = 1'b0;
        endcase
    end

endmodule
