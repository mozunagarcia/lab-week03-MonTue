module debouncer #(
    parameter THRESHOLD = 500_000 // 20ms @ 25MHz
)(
    input logic clk,
    input logic btn_raw,
    output logic btn_clean = 0
);

    logic [18:0] count = 0;
    logic btn_sync_0 = 0, btn_sync_1 = 0;

    always_ff @(posedge clk) begin
        btn_sync_0 <= btn_raw;
        btn_sync_1 <= btn_sync_0;
    end

    always_ff @(posedge clk) begin
        if (btn_sync_1 !== btn_clean) begin
            if (count < THRESHOLD) begin
                count <= count + 1;
            end else begin
                btn_clean <= btn_sync_1;
                count <= 0;
            end
        end else begin
            count <= 0;
        end
    end

endmodule