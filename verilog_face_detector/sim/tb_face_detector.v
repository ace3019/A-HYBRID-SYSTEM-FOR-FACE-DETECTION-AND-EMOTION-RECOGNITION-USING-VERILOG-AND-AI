// tb_face_detector.v
// Testbench for Haar Cascade Face Detector

`timescale 1ns / 1ps

module tb_face_detector;

    // Parameters
    parameter IMG_WIDTH = 64;
    parameter IMG_HEIGHT = 64;
    parameter PIXEL_WIDTH = 8;
    parameter CLK_PERIOD = 10;  // 100MHz clock
    
    // Signals
    reg clk;
    reg rst;
    reg start;
    reg [PIXEL_WIDTH-1:0] pixel_in;
    reg pixel_valid;
    
    wire face_detected;
    wire [7:0] face_x;
    wire [7:0] face_y;
    wire [7:0] face_scale;
    wire done;
    
    // Test image memory
    reg [PIXEL_WIDTH-1:0] test_image [0:IMG_HEIGHT-1][0:IMG_WIDTH-1];
    
    // Counters for image loading
    integer x, y;
    integer pixel_count;
    
    // DUT instantiation
    face_detector #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .PIXEL_WIDTH(PIXEL_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .face_detected(face_detected),
        .face_x(face_x),
        .face_y(face_y),
        .face_scale(face_scale),
        .done(done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test image initialization
    initial begin
        // Load test image from hex file
        $readmemh("image.txt", test_image);
        $display("Loaded test image from image.txt");
    end
    
    // Main test sequence
    initial begin
        // Setup waveform dump
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_face_detector);
        
        // Initialize signals
        rst = 1;
        start = 0;
        pixel_in = 0;
        pixel_valid = 0;
        pixel_count = 0;
        
        $display("========================================");
        $display("Haar Cascade Face Detector Testbench");
        $display("========================================");
        $display("Image size: %dx%d", IMG_WIDTH, IMG_HEIGHT);
        $display("Clock period: %d ns", CLK_PERIOD);
        
        // Reset
        #(CLK_PERIOD * 10);
        rst = 0;
        #(CLK_PERIOD * 5);
        
        $display("Starting face detection...");
        
        // Start detection and load image pixels
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Feed pixels to the detector
        for (y = 0; y < IMG_HEIGHT; y = y + 1) begin
            for (x = 0; x < IMG_WIDTH; x = x + 1) begin
                @(posedge clk);
                pixel_in = test_image[y][x];
                pixel_valid = 1;
                pixel_count = pixel_count + 1;
                
                if (pixel_count % 512 == 0) begin
                    $display("Loaded %d pixels...", pixel_count);
                end
            end
        end
        
        @(posedge clk);
        pixel_valid = 0;
        
        $display("All %d pixels loaded", pixel_count);
        $display("Waiting for detection to complete...");
        
        // Wait for detection to complete
        wait(done);
        
        #(CLK_PERIOD * 10);
        
        // Display results
        $display("========================================");
        $display("Detection Results:");
        $display("========================================");
        if (face_detected) begin
            $display("✓ FACE DETECTED!");
            $display("  Position: (%d, %d)", face_x, face_y);
            $display("  Scale: %d", face_scale);
        end else begin
            $display("✗ No face detected");
        end
        $display("========================================");
        
        // End simulation
        #(CLK_PERIOD * 100);
        $display("Simulation completed");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 9000000);  // 90ms timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    // Monitor key signals
    always @(posedge clk) begin
        if (done) begin
            $display("Time %t: Detection completed", $time);
        end
           if (dut.control.state != 0) begin
               $display("Time %t: FSM State = %d, ii_done=%b, stage_done=%b, window_x=%d, window_y=%d", 
                        $time, dut.control.state, dut.control.ii_done, dut.control.stage_done,
                        dut.control.window_x, dut.control.window_y);
           end
    end

endmodule
