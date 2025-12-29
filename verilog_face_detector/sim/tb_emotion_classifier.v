// tb_emotion_classifier.v
// Testbench for Face Detection + Emotion Classification

`timescale 1ns / 1ps

module tb_emotion_classifier;

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
    
    // Counters
    integer x, y;
    integer pixel_count;
    
    // DUT
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
    
    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Load Image
    initial begin
        // Get image filename from plusarg or default
        if (!$value$plusargs("IMAGE=%s", x)) begin
            $readmemh("image.txt", test_image);
            $display("Loaded image.txt (default)");
        end else begin
            // Note: In Verilog, passing strings to readmemh is tricky depending on simulator.
            // For simplicity, we stick to reading "image.txt" which the runner will prepare.
             $readmemh("image.txt", test_image);
             $display("Loaded image.txt");
        end
    end
    
    // Main
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_emotion_classifier);
        
        rst = 1;
        start = 0;
        pixel_in = 0;
        pixel_valid = 0;
        pixel_count = 0;
        
        #(CLK_PERIOD * 10);
        rst = 0;
        #(CLK_PERIOD * 5);
        
        $display("Starting Co-Simulation...");
        
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Feed pixels
        for (y = 0; y < IMG_HEIGHT; y = y + 1) begin
            for (x = 0; x < IMG_WIDTH; x = x + 1) begin
                @(posedge clk);
                pixel_in = test_image[y][x];
                pixel_valid = 1;
                pixel_count = pixel_count + 1;
            end
        end
        
        @(posedge clk);
        pixel_valid = 0;
        
        wait(done);
        #(CLK_PERIOD * 10);
        
        if (face_detected) begin
            $display("✓ Face detected at (%d, %d)", face_x, face_y);
            $display("Calling Python Emotion Classifier...");
            
            // VPI Call
            // Scale is usually the size of the window. Haar default is 24x24.
            // The 'face_scale' output from detector might be the scale factor index or size.
            // Let's assume we send x, y, width, height.
            // Width/Height = 24 * (1.25^scale). 
            // For this test, we just pass dummy width/height (24) or the scale value.
            
            $send_roi_for_emotion(face_x, face_y, 24, 24);
            
        end else begin
            $display("✗ No face detected.");
        end
        
        $finish;
    end
    
    // Watchdog
    initial begin
        #(CLK_PERIOD * 20000000); // 200ms
        $display("TIMEOUT");
        $finish;
    end

endmodule
