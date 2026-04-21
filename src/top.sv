module top #(
    parameter int DEBOUNCE_THRESHOLD = 500_000
) (
    input  logic clk,
    input  logic btn1,
    input  logic btn2,
    input  logic [3:0] sw,
    output logic [6:0] seg,
    output logic dp,
    output logic led_r,        // on-board RGB: red   B11 (active-low)
    output logic led_g,        // on-board RGB: green A11 (active-low)
    output logic led_b         // on-board RGB: blue  A12 (active-low)
);

    logic btn1_debounced, btn2_debounced;

    debouncer #(.THRESHOLD(DEBOUNCE_THRESHOLD)) deb1_inst (
        .clk(clk),
        .btn_raw(btn1),
        .btn_clean(btn1_debounced)
    );

    debouncer #(.THRESHOLD(DEBOUNCE_THRESHOLD)) deb2_inst (
        .clk(clk),
        .btn_raw(btn2),
        .btn_clean(btn2_debounced)
    );

    typedef enum logic { IDLE = 1'b0, PRESSED = 1'b1 } state_t;

    state_t state1 = IDLE;
    logic [3:0] duty_cycle = 4'd0;

    always_ff @(posedge clk) begin
        case (state1)
            IDLE: begin
                if (btn1_debounced)
                    state1 <= PRESSED;
            end
            PRESSED: begin
                if (!btn1_debounced) begin
                    state1 <= IDLE;
                    if (duty_cycle == 4'd10)
                        duty_cycle <= 4'd0;
                    else
                        duty_cycle <= duty_cycle + 4'd1;
                end
            end
            default: state1 <= IDLE;
        endcase
    end

    state_t state2 = IDLE;
    logic [3:0] duty_cycle_2 = 4'd0;

    always_ff @(posedge clk) begin
        case (state2)
            IDLE: begin
                if (btn2_debounced)
                    state2 <= PRESSED;
            end
            PRESSED: begin
                if (!btn2_debounced) begin
                    state2 <= IDLE;
                    if (duty_cycle_2 == 4'd10)
                        duty_cycle_2 <= 4'd0;
                    else
                        duty_cycle_2 <= duty_cycle_2 + 4'd1;
                end
            end
            default: state2 <= IDLE;
        endcase
    end

    logic [3:0] pwm_counter = 4'd0;

    always_ff @(posedge clk) begin
        if (pwm_counter == 4'd9)
            pwm_counter <= 4'd0;
        else
            pwm_counter <= pwm_counter + 4'd1;
    end

    assign led_r = (pwm_counter < duty_cycle) ? 1'b1 : 1'b0;
    assign led_g = (pwm_counter < duty_cycle_2) ? 1'b1 : 1'b0;
    assign led_b = (pwm_counter < duty_cycle_2) ? 1'b1 : 1'b0;

    // display duty_cycle on 7-segment via Lab 2 decoder
    logic [7:0] seg7;

    decoder dec_inst (
        .val1(duty_cycle),
        .seg7(seg7)
    );

    assign seg = {seg7[0], seg7[1], seg7[2], seg7[3], seg7[4], seg7[5], seg7[6]};
    assign dp  = seg7[7];

endmodule