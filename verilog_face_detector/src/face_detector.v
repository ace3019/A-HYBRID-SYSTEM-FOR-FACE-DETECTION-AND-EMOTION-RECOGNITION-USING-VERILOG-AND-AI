// face_detector.v
// Top-level module integrating all components for Haar Cascade face detection

module face_detector #(
    parameter IMG_WIDTH = 64,
    parameter IMG_HEIGHT = 64,
    parameter PIXEL_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter FIXED_POINT_FRAC = 16
)(
    input clk,
    input rst,
    input start,                          // Start detection
    
    // Image input interface
    input [PIXEL_WIDTH-1:0] pixel_in,
    input pixel_valid,
    
    // Detection outputs
    output face_detected,
    output [7:0] face_x,
    output [7:0] face_y,
    output [7:0] face_scale,
    output done
);

    wire rect_sum_valid;
    wire [23:0] rect_sum;

    // Control FSM and Stage Evaluator interface
    wire stage_start, stage_passed, stage_done;
    wire eval_cascade_state;
    wire [16:0] fsm_cascade_addr, se_cascade_addr;
    wire [16:0] fsm_classifier_base_addr;
    wire signed [DATA_WIDTH-1:0] fsm_stage_threshold;
    wire [15:0] fsm_num_classifiers;

    wire [7:0] window_x, window_y, window_scale;

    wire [16:0] cascade_addr;
    wire [DATA_WIDTH-1:0] cascade_data;
    wire [16:0] feature_lut_addr;
    wire [DATA_WIDTH-1:0] feature_lut_data;


    // Mux for cascade ROM address
    assign cascade_addr = eval_cascade_state ? se_cascade_addr : fsm_cascade_addr;

    wire calc_start, calc_done;
    wire [11:0] feature_index;
    wire signed [DATA_WIDTH-1:0] feature_value;

    wire wc_start, wc_done;
    wire signed [DATA_WIDTH-1:0] wc_feature_val, wc_threshold;
    wire signed [DATA_WIDTH-1:0] wc_left_val, wc_right_val, wc_output;

    // Internal signals for module interconnections
    wire ii_start, ii_done;
    wire [15:0] query_x1, query_y1, query_x2, query_y2;
    wire query_valid;

    // Module instantiations

    // Integral Image Unit
    integral_image #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .SUM_WIDTH(24)
    ) integral_img (
        .clk(clk),
        .rst(rst),
        .start(ii_start),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .query_x1(query_x1),
        .query_y1(query_y1),
        .query_x2(query_x2),
        .query_y2(query_y2),
        .query_valid(query_valid),
        .rect_sum(rect_sum),
        .rect_sum_valid(rect_sum_valid),
        .done(ii_done)
    );

    // Haar Cascade ROM
    haar_cascade_rom #(
        .ADDR_WIDTH(17),
        .DATA_WIDTH(DATA_WIDTH)
    ) cascade_rom (
        .clk(clk),
        .address(cascade_addr),
        .data(cascade_data)
    );

    // Feature LUT ROM
    feature_lut_rom #(
        .ADDR_WIDTH(17),
        .DATA_WIDTH(DATA_WIDTH)
    ) feature_lut_rom (
        .clk(clk),
        .address(feature_lut_addr),
        .data(feature_lut_data)
    );

    // Feature Calculator
    feature_calculator #(
        .DATA_WIDTH(DATA_WIDTH),
        .SUM_WIDTH(24),
        .FIXED_POINT_FRAC(FIXED_POINT_FRAC),
        .FEATURE_LUT_BASE_ADDR(0)
    ) feat_calc (
        .clk(clk),
        .rst(rst),
        .start(calc_start),
        .feature_index(feature_index),
        .window_x(window_x),
        .window_y(window_y),
        .window_scale(window_scale),
        .query_x1(query_x1),
        .query_y1(query_y1),
        .query_x2(query_x2),
        .query_y2(query_y2),
        .query_valid(query_valid),
        .rect_sum(rect_sum),
        .rect_sum_valid(rect_sum_valid),
        .feature_addr(feature_lut_addr),
        .feature_data(feature_lut_data),
        .feature_value(feature_value),
        .done(calc_done)
    );

    // Weak Classifier
    weak_classifier #(
        .DATA_WIDTH(DATA_WIDTH)
    ) weak_clf (
        .clk(clk),
        .rst(rst),
        .start(wc_start),
        .feature_value(wc_feature_val),
        .threshold(wc_threshold),
        .left_val(wc_left_val),
        .right_val(wc_right_val),
        .classifier_output(wc_output),
        .done(wc_done)
    );

    // Stage Evaluator
    stage_evaluator #(
        .DATA_WIDTH(DATA_WIDTH)
    ) stage_eval (
        .clk(clk),
        .rst(rst),
        .start(stage_start),
        .classifier_base_addr(fsm_classifier_base_addr),
        .stage_threshold(fsm_stage_threshold),
        .num_classifiers(fsm_num_classifiers),
        .cascade_addr(se_cascade_addr),
        .cascade_data(cascade_data),
        .calc_start(calc_start),
        .feature_index(feature_index),
        .feature_value(feature_value),
        .calc_done(calc_done),
        .wc_start(wc_start),
        .wc_feature_val(wc_feature_val),
        .wc_threshold(wc_threshold),
        .wc_left_val(wc_left_val),
        .wc_right_val(wc_right_val),
        .wc_output(wc_output),
        .wc_done(wc_done),
        .stage_passed(stage_passed),
        .stage_done(stage_done)
    );

    // Control FSM
    control_fsm #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .NUM_STAGES(25)
    ) control (
        .clk(clk),
        .rst(rst),
        .start(start),
        .cascade_addr(fsm_cascade_addr),
        .cascade_data(cascade_data),
        .ii_start(ii_start),
        .ii_done(ii_done),
        .stage_start(stage_start),
        .classifier_base_addr(fsm_classifier_base_addr),
        .stage_threshold(fsm_stage_threshold),
        .num_classifiers(fsm_num_classifiers),
        .stage_passed(stage_passed),
        .stage_done(stage_done),
        .eval_cascade_state(eval_cascade_state),
        .window_x(window_x),
        .window_y(window_y),
        .window_scale(window_scale),
        .face_detected(face_detected),
        .face_x(face_x),
        .face_y(face_y),
        .face_scale(face_scale),
        .done(done)
    );

endmodule