// stage_evaluator.v
// Evaluates one complete cascade stage
// Sums all weak classifier outputs and compares to stage threshold

module stage_evaluator #(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input start,                                    // Start stage evaluation
    input [16:0] classifier_base_addr,              // Base address for this stage's classifiers
    input signed [DATA_WIDTH-1:0] stage_threshold,  // Stage threshold
    input [15:0] num_classifiers,                   // Number of weak classifiers in stage

    // Interface to cascade ROM
    output reg [16:0] cascade_addr,
    input [DATA_WIDTH-1:0] cascade_data,

    // Interface to feature calculator
    output reg calc_start,
    output reg [11:0] feature_index,
    input signed [DATA_WIDTH-1:0] feature_value,
    input calc_done,

    // Interface to weak classifier
    output reg wc_start,
    output reg signed [DATA_WIDTH-1:0] wc_feature_val,
    output reg signed [DATA_WIDTH-1:0] wc_threshold,
    output reg signed [DATA_WIDTH-1:0] wc_left_val,
    output reg signed [DATA_WIDTH-1:0] wc_right_val,
    input signed [DATA_WIDTH-1:0] wc_output,
    input wc_done,

    // Output
    output reg stage_passed,     // 1 if stage passed, 0 if rejected
    output reg stage_done
);

    // States
    localparam IDLE = 3'b000;
    localparam READ_CLASSIFIER = 3'b001;
    localparam CALC_FEATURE = 3'b010;
    localparam EVAL_WEAK = 3'b011;
    localparam ACCUMULATE = 3'b100;
    localparam COMPARE = 3'b101;
    localparam WAIT_ROM = 3'b110;

    reg [2:0] state;
    reg [15:0] classifier_counter;
    reg signed [DATA_WIDTH-1:0] stage_sum;  // Sum of all weak classifier outputs
    reg [16:0] current_classifier_addr;     // Address of current classifier data being read
    reg [2:0] rom_read_step;                // Track which parameter we're reading

    // Temporary storage for classifier parameters
    reg [11:0] current_feature_idx;
    reg signed [DATA_WIDTH-1:0] current_threshold;
    reg signed [DATA_WIDTH-1:0] current_left;
    reg signed [DATA_WIDTH-1:0] current_right;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            stage_done <= 0;
            stage_passed <= 0;
            calc_start <= 0;
            wc_start <= 0;
            classifier_counter <= 0;
            stage_sum <= 0;
            rom_read_step <= 0;
        end else begin
            case (state)
                IDLE: begin
                    stage_done <= 0;
                    if (start) begin
                        state <= WAIT_ROM;
                        classifier_counter <= 0;
                        stage_sum <= 0;
                        rom_read_step <= 0;
                        current_classifier_addr <= classifier_base_addr;
                        cascade_addr <= classifier_base_addr;
                    end
                end
                
                   WAIT_ROM: begin
                       // Wait one cycle for ROM to output data
                       state <= READ_CLASSIFIER;
                   end
               
                READ_CLASSIFIER: begin
                    // Read classifier parameters one at a time
                    case (rom_read_step)
                        0: begin
                            current_feature_idx <= cascade_data[11:0];
                            feature_index <= cascade_data[11:0];
                            cascade_addr <= current_classifier_addr + 1;
                            rom_read_step <= 1;
                            state <= WAIT_ROM;
                        end
                        1: begin
                            current_threshold <= cascade_data;
                            cascade_addr <= current_classifier_addr + 2;
                            rom_read_step <= 2;
                            state <= WAIT_ROM;
                        end
                        2: begin
                            current_left <= cascade_data;
                            cascade_addr <= current_classifier_addr + 3;
                            rom_read_step <= 3;
                            state <= WAIT_ROM;
                        end
                        3: begin
                            current_right <= cascade_data;
                            rom_read_step <= 0;
                            state <= CALC_FEATURE;
                            calc_start <= 1;
                        end
                    endcase
                end
                
                CALC_FEATURE: begin
                    calc_start <= 0;
                    if (calc_done) begin
                        state <= EVAL_WEAK;
                        wc_feature_val <= feature_value;
                        wc_threshold <= current_threshold;
                        wc_left_val <= current_left;
                        wc_right_val <= current_right;
                        wc_start <= 1;
                    end
                end
                
                EVAL_WEAK: begin
                    wc_start <= 0;
                    if (wc_done) begin
                        state <= ACCUMULATE;
                    end
                end
                
                ACCUMULATE: begin
                    // Add weak classifier output to stage sum
                    stage_sum <= stage_sum + wc_output;

                    // Move to next classifier
                    classifier_counter <= classifier_counter + 1;
                    if (classifier_counter + 1 >= num_classifiers) begin
                        state <= COMPARE;
                    end else begin
                        state <= WAIT_ROM;
                        current_classifier_addr <= current_classifier_addr + 4;  // Move to next classifier
                        cascade_addr <= current_classifier_addr + 4;
                        rom_read_step <= 0;
                    end
                end
                
                COMPARE: begin
                    // Compare stage sum to threshold
                    if (stage_sum >= stage_threshold) begin
                        stage_passed <= 1;  // Pass - continue to next stage
                    end else begin
                        stage_passed <= 0;  // Fail - reject as not a face
                    end
                    stage_done <= 1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

    // Debug logging
    reg [2:0] prev_state;
    initial prev_state = 3'h7;
    always @(posedge clk) begin
        if (state != prev_state) begin
            $display("[SE] Time: %t | State: %d | Classifier: %d | Sum: %d", 
                     $time, state, classifier_counter, stage_sum);
            prev_state <= state;
        end
    end

endmodule