`include "src/top.sv"
`include "src/debouncer.sv"
`timescale 1ns/1ps

module top_tb;

    // signals
    logic clk_tb = 1'b0;
    logic btn_tb = 1'b0;
    logic led_tb;

    // We override DEBOUNCE_THRESHOLD to a small number for simulation.
    // A setting of 10 means the button must be stable for 10 clock cycles.
    localparam THRESHOLD = 10;

    // DUT instantiation
    top #(.DEBOUNCE_THRESHOLD(THRESHOLD)) dut (
        .clk  (clk_tb),
        .btn1 (btn_tb),
        .btn2 (1'b0),
        .sw   (4'b0000),
        .seg  (),
        .dp   (),
        .led_r(),
        .led_g(led_tb),
        .led_b()
    );

    // Clock: 40 ns period (25 MHz for iCESugar-Pro)
    localparam CLK_PERIOD = 40;
    always #(CLK_PERIOD/2) clk_tb = ~clk_tb;

    initial begin
        $dumpfile("build/top.vcd");
        $dumpvars(0, top_tb);

        // 1. Reset Phase
        repeat(5) @(posedge clk_tb);
        $display("t=%0t | Start: LED=%b (expect 0)", $time, led_tb);

        // 2. GLITCH TEST: Press button for only 3 cycles (shorter than THRESHOLD=10)
        $display("t=%0t | Injecting 3-cycle glitch...", $time);
        btn_tb = 1'b1;
        repeat(3) @(posedge clk_tb);
        btn_tb = 1'b0;
        repeat(15) @(posedge clk_tb); 
        $display("t=%0t | After glitch: LED=%b (expect 0 - glitch should be ignored)", $time, led_tb);

        // 3. VALID PRESS: Press button for 20 cycles (longer than THRESHOLD=10)
        $display("t=%0t | Performing valid press...", $time);
        btn_tb = 1'b1;
        repeat(20) @(posedge clk_tb);
        $display("t=%0t | Button held. LED=%b (expect 0 - waiting for release)", $time, led_tb);
        
        btn_tb = 1'b0;
        repeat(20) @(posedge clk_tb); // Wait for debouncer to see the release
        $display("t=%0t | After release: LED=%b (expect 1)", $time, led_tb);

        // 4. ANOTHER PRESS: Toggle it back OFF
        $display("t=%0t | Toggling OFF...", $time);
        btn_tb = 1'b1;
        repeat(20) @(posedge clk_tb);
        btn_tb = 1'b0;
        repeat(20) @(posedge clk_tb);
        $display("t=%0t | Final State: LED=%b (expect 0)", $time, led_tb);

        $finish;
    end

endmodule