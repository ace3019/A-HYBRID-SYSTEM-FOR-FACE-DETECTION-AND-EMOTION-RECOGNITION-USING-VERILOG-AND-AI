// tb_control_fsm.v
// Testbench for the control FSM of the Haar Cascade Face Detector

`timescale 1ns / 1ps

module tb_control_fsm;

    // Parameters
    parameter CLK_PERIOD = 10;  // 100MHz clock

    // Signals
    reg clk;
    reg rst;
    reg start;
    reg ii_done;
    reg stage_done;
    reg stage_passed;
    reg last_stage;
    reg last_window;

    wire fsm_state;
    wire stage_start;
    wire next_window_s;

    // DUT instantiation
    control_fsm dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .ii_done(ii_done),
        .stage_done(stage_done),
        .stage_passed(stage_passed),
        .last_stage(last_stage),
        .last_window(last_window),
        .state(fsm_state),
        .stage_start(stage_start),
        .next_window(next_window_s)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Main test sequence
    initial begin
        // Setup waveform dump
        $dumpfile("waveform_fsm.vcd");
        $dumpvars(0, tb_control_fsm);

        // Initialize signals
        rst = 1;
        start = 0;
        ii_done = 0;
        stage_done = 0;
        stage_passed = 0;
        last_stage = 0;
        last_window = 0;

        $display("========================================");
        $display("Control FSM Testbench");
        $display("========================================");

        // Reset
        #(CLK_PERIOD * 10);
        rst = 0;
        #(CLK_PERIOD * 5);

        // **Test Case 1: Normal face detection flow**
        $display("Test Case 1: Normal face detection flow");

        // Start the FSM
        start = 1;
        @(posedge clk);
        start = 0;

        // Check that the FSM goes to the COMPUTE_INTEGRAL state
        assert(fsm_state == 1) else $fatal("FSM did not go to COMPUTE_INTEGRAL state");

        // Wait for the integral image to be computed
        ii_done = 1;
        @(posedge clk);
        ii_done = 0;

        // Check that the FSM goes to the INIT_SCAN state
        assert(fsm_state == 2) else $fatal("FSM did not go to INIT_SCAN state");

        // Check that the FSM goes to the EVAL_CASCADE state
        @(posedge clk);
        assert(fsm_state == 3) else $fatal("FSM did not go to EVAL_CASCADE state");

        // Simulate a few stages
        for (integer i = 0; i < 5; i = i + 1) begin
            stage_done = 1;
            stage_passed = 1;
            @(posedge clk);
            stage_done = 0;
            assert(fsm_state == 4) else $fatal("FSM did not go to NEXT_STAGE state");
            @(posedge clk);
            assert(fsm_state == 3) else $fatal("FSM did not go to EVAL_CASCADE state");
        end

        // Simulate a failed stage
        stage_done = 1;
        stage_passed = 0;
        @(posedge clk);
        stage_done = 0;
        assert(fsm_state == 5) else $fatal("FSM did not go to NEXT_WINDOW state");

        // Simulate a few more windows
        for (integer i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            assert(fsm_state == 3) else $fatal("FSM did not go to EVAL_CASCADE state");
            stage_done = 1;
            stage_passed = 0;
            @(posedge clk);
            stage_done = 0;
            assert(fsm_state == 5) else $fatal("FSM did not go to NEXT_WINDOW state");
        end

        // Simulate the last window
        last_window = 1;
        @(posedge clk);
        assert(fsm_state == 3) else $fatal("FSM did not go to EVAL_CASCADE state");
        stage_done = 1;
        stage_passed = 0;
        @(posedge clk);
        stage_done = 0;
        assert(fsm_state == 6) else $fatal("FSM did not go to FINISH state");

        $display("Test Case 1 passed!");

        // **Test Case 2: Last stage passed**
        $display("Test Case 2: Last stage passed");

        // Reset the FSM
        rst = 1;
        #(CLK_PERIOD * 10);
        rst = 0;
        #(CLK_PERIOD * 5);

        // Start the FSM
        start = 1;
        @(posedge clk);
        start = 0;

        // Go to the last stage
        ii_done = 1;
        @(posedge clk);
        ii_done = 0;
        @(posedge clk);
        last_stage = 1;

        // Pass the last stage
        stage_done = 1;
        stage_passed = 1;
        @(posedge clk);
        stage_done = 0;

        // Check that the FSM goes to the FINISH state
        assert(fsm_state == 6) else $fatal("FSM did not go to FINISH state");

        $display("Test Case 2 passed!");

        // End simulation
        #(CLK_PERIOD * 100);
        $display("Simulation completed");
        $finish;
    end

endmodule
