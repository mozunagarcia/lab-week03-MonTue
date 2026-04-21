`include "src/top.sv"
`include "src/debouncer.sv"
`include "src/decoder.sv"
`timescale 1ns/1ps

module top_tb;

    // signals
    logic clk_tb = 1'b0;
    logic btn_tb = 1'b0;

    // We override DEBOUNCE_THRESHOLD to a small number for simulation.
    // A setting of 10 means the button must be stable for 10 clock cycles.
    localparam THRESHOLD = 10;

    // DUT instantiation
    top #(.DEBOUNCE_THRESHOLD(THRESHOLD)) dut (
        .clk  (clk_tb),
        .btn1 (btn_tb),
        .btn2 (1'b0),
        .sw (4'b0000),
        .seg (),
        .dp (),
        .led_r(),
        .led_g(),
        .led_b()
    );

    // Clock: 40 ns period (25 MHz for iCESugar-Pro)
    localparam CLK_PERIOD = 40;
    always #(CLK_PERIOD/2) clk_tb = ~clk_tb;

    // Helper task: perform one clean press-release cycle
    task press_button;
        btn_tb = 1'b1;
        repeat(20) @(posedge clk_tb);
        btn_tb = 1'b0;
        repeat(20) @(posedge clk_tb);
    endtask

    initial begin
        $dumpfile("build/top.vcd");
        $dumpvars(0, top_tb);

        // 1. Reset Phase
        repeat(5) @(posedge clk_tb);
        $display("t=%0t | Start: duty_cycle=%0d (expect 0)", $time, dut.duty_cycle);

        // 2. GLITCH TEST: Press button for only 3 cycles (shorter than THRESHOLD=10)
        $display("t=%0t | Injecting 3-cycle glitch...", $time);
        btn_tb = 1'b1;
        repeat(3) @(posedge clk_tb);
        btn_tb = 1'b0;
        repeat(15) @(posedge clk_tb);
        $display("t=%0t | After glitch: duty_cycle=%0d (expect 0 - glitch ignored)", $time, dut.duty_cycle);

        // 3. Press 9 times: duty_cycle should reach 9
        $display("t=%0t | Pressing 9 times...", $time);
        repeat(9) press_button();
        $display("t=%0t | After 9 presses: duty_cycle=%0d (expect 9)", $time, dut.duty_cycle);

        // 4. One more press: duty_cycle should wrap back to 0
        $display("t=%0t | Pressing once more (wrap check)...", $time);
        press_button();
        $display("t=%0t | After 10th press: duty_cycle=%0d (expect 0)", $time, dut.duty_cycle);

        // 5. Two more presses to confirm counting resumes from 0
        repeat(2) press_button();
        $display("t=%0t | After 2 more presses: duty_cycle=%0d (expect 2)", $time, dut.duty_cycle);

        $finish;
    end

endmodule