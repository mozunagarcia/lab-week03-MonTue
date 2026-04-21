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

    logic btn1_debounced;

    debouncer #(.THRESHOLD(DEBOUNCE_THRESHOLD)) deb_inst (
        .clk(clk),
        .btn_raw(btn1),
        .btn_clean(btn1_debounced)
    );

    typedef enum logic { IDLE = 1'b0, PRESSED = 1'b1 } state_t;

    state_t state = IDLE;
    logic [3:0] duty_cycle = 4'd0;

    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                if (btn1_debounced)
                    state <= PRESSED;
            end
            PRESSED: begin
                if (!btn1_debounced) begin
                    state <= IDLE;
                    if (duty_cycle == 4'd9)
                        duty_cycle <= 4'd0;
                    else
                        duty_cycle <= duty_cycle + 4'd1;
                end
            end
            default: state <= IDLE;
        endcase
    end

    assign led_r = 1'b0;
    assign led_g = 1'b0;
    assign led_b = 1'b0;

    // display duty_cycle on 7-segment via Lab 2 decoder
    logic [7:0] seg7;

    decoder dec_inst (
        .val1(duty_cycle),
        .seg7(seg7)
    );

    assign seg = {seg7[0], seg7[1], seg7[2], seg7[3], seg7[4], seg7[5], seg7[6]};
    assign dp  = seg7[7];

endmodule