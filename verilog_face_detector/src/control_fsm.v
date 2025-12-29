// control_fsm.v
// Main control finite state machine for face detection
// Coordinates all modules and implements the cascade detection flow

module control_fsm #(
    parameter IMG_WIDTH = 64,
    parameter IMG_HEIGHT = 64,
    parameter NUM_STAGES = 25
)(
    input clk,
    input rst,
    input start,                    // Start detection

    // Interface to cascade ROM
    output reg [16:0] cascade_addr,
    input [31:0] cascade_data,

    // Interface to integral image module
    output reg ii_start,
    input ii_done,

    // Interface to stage evaluator
    output reg stage_start,
    output reg [16:0] classifier_base_addr, // New: Pass base address to evaluator
    output reg signed [31:0] stage_threshold,   // New: Pass threshold to evaluator
    output reg [15:0] num_classifiers,      // New: Pass count to evaluator
    input stage_passed,
    input stage_done,

    output reg eval_cascade_state,       // New: Indicates when evaluator is active

    // Detection window control
    output reg [7:0] window_x,
    output reg [7:0] window_y,
    output reg [7:0] window_scale,

    // Outputs
    output reg face_detected,
    output reg [7:0] face_x, face_y,     // Face location if detected
    output reg [7:0] face_scale,          // Face scale if detected
    output reg done
);

    // States
    localparam IDLE = 4'b0000;
    localparam COMPUTE_INTEGRAL = 4'b0001;
    localparam INIT_SCAN = 4'b0010;
    localparam READ_STAGE_HEADER = 4'b0011; // New state
    localparam EVAL_CASCADE = 4'b0100;
    localparam NEXT_STAGE = 4'b0101;
    localparam NEXT_WINDOW = 4'b0110;
    localparam FINISH = 4'b0111;

    reg [3:0] state;
    reg [4:0] stage_counter;
    reg cascade_passed;
    reg [16:0] stage_base_addr; // Base address of the current stage in ROM
    reg [1:0] read_step; // For multi-cycle reads

    
    // Scanning parameters
    localparam MIN_WINDOW_SIZE = 24;
    localparam STEP_SIZE = 4;        // Slide window by 4 pixels
    localparam SCALE_STEP = 8;       // Scale increment (fixed point)
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            // ... (reset logic unchanged) ...
            eval_cascade_state <= 0;
        end else begin
            // Default assignments
            eval_cascade_state <= 0;

            // Debug print
            if (state != IDLE) begin
                 //$display("Time: %t, State: %d, Window: (%d, %d), Scale: %d, Stage: %d, Passed: %d", $time, state, window_x, window_y, window_scale, stage_counter, cascade_passed);
            end

            case (state)
                IDLE: begin
                    done <= 0;
                    face_detected <= 0;
                    if (start) begin
                        state <= COMPUTE_INTEGRAL;
                        ii_start <= 1;
                    end
                end
                
                COMPUTE_INTEGRAL: begin
                    ii_start <= 0;
                    if (ii_done) begin
                        state <= INIT_SCAN;
                        window_x <= 0;
                        window_y <= 0;
                        window_scale <= 8'd255;  // 1.0 scale
                        stage_base_addr <= 0; // Start at the beginning of the cascade
                    end
                end
                
                INIT_SCAN: begin
                    // Start cascade evaluation for current window
                    stage_counter <= 0;
                    cascade_passed <= 1;  // Assume pass until a stage fails
                    state <= READ_STAGE_HEADER;
                    read_step <= 0;
                    cascade_addr <= stage_base_addr; // Read stage threshold
                end

                READ_STAGE_HEADER: begin
                    case (read_step)
                        0: begin // Wait 1 cycle for ROM read
                            read_step <= 1;
                        end
                        1: begin // Latch threshold, request num_classifiers
                            stage_threshold <= cascade_data;
                            cascade_addr <= stage_base_addr + 1;
                            read_step <= 2;
                        end
                        2: begin // Wait 1 cycle for ROM read
                            read_step <= 3;
                        end
                        3: begin // Latch num_classifiers, start evaluation
                            num_classifiers <= cascade_data[15:0];
                            classifier_base_addr <= stage_base_addr + 2;
                            state <= EVAL_CASCADE;
                            stage_start <= 1;
                            read_step <= 0;
                        end
                    endcase
                end
                
                EVAL_CASCADE: begin
                    eval_cascade_state <= 1;
                    stage_start <= 0;
                    if (stage_done) begin
                        if (!stage_passed) begin
                            // Stage failed - this window is not a face
                            cascade_passed <= 0;
                            state <= NEXT_WINDOW;
                        end else begin
                            state <= NEXT_STAGE;
                        end
                    end
                end
                
                NEXT_STAGE: begin
                    // Advance to the next stage's header in the ROM
                    stage_base_addr <= stage_base_addr + 2 + (num_classifiers * 4);
                    stage_counter <= stage_counter + 1;

                    if (stage_counter + 1 >= NUM_STAGES) begin
                        // All stages passed - face detected!
                        face_detected <= 1;
                        face_x <= window_x;
                        face_y <= window_y;
                        face_scale <= window_scale;
                        state <= FINISH;
                    end else begin
                        // Read the next stage's header
                        state <= READ_STAGE_HEADER;
                        read_step <= 0;
                        cascade_addr <= stage_base_addr + 2 + (num_classifiers * 4);
                    end
                end
                
                NEXT_WINDOW: begin
                    // Move to next detection window
                    if (window_x + MIN_WINDOW_SIZE + STEP_SIZE < IMG_WIDTH) begin
                        window_x <= window_x + STEP_SIZE;
                        state <= INIT_SCAN;
                        stage_base_addr <= 0; // Reset for new window
                    end else if (window_y + MIN_WINDOW_SIZE + STEP_SIZE < IMG_HEIGHT) begin
                        window_x <= 0;
                        window_y <= window_y + STEP_SIZE;
                        state <= INIT_SCAN;
                        stage_base_addr <= 0; // Reset for new window
                    end else begin
                        // Scanned entire image at this scale
                        state <= FINISH;
                    end
                end
                
                FINISH: begin
                    done <= 1;
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

    // Debug logging
    reg [3:0] prev_state;
    initial prev_state = 4'hF; 
    always @(posedge clk) begin
        if (state != prev_state) begin
            $display("Time: %t | State: %d | Win(%d,%d) Scale:%d | Stage: %d | Pass: %d", 
                     $time, state, window_x, window_y, window_scale, stage_counter, cascade_passed);
            prev_state <= state;
        end
    end

endmodule
