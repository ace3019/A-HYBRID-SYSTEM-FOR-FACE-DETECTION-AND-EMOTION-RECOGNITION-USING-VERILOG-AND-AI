// feature_calculator.v
// Calculates Haar feature values from rectangle sums
// Feature = sum of (rectangle_area * weight) for all rectangles in the feature

module feature_calculator #(
    parameter DATA_WIDTH = 32,
    parameter SUM_WIDTH = 24,
    parameter FIXED_POINT_FRAC = 16,
    parameter FEATURE_LUT_BASE_ADDR = 0
)(
    input clk,
    input rst,
    input start,                              // Start feature calculation
    input [11:0] feature_index,               // Which feature to calculate
    input [7:0] window_x, window_y,           // Current detection window position
    input [7:0] window_scale,                 // Window scale factor
    
    // Interface to integral image
    output reg [15:0] query_x1, query_y1,
    output reg [15:0] query_x2, query_y2,
    output reg query_valid,
    input [SUM_WIDTH-1:0] rect_sum,
    input rect_sum_valid,
    
    // Interface to feature ROM
    output reg [16:0] feature_addr,
    input [DATA_WIDTH-1:0] feature_data,
    
    // Output
    output reg signed [DATA_WIDTH-1:0] feature_value,  // Calculated feature value (fixed-point)
    output reg done
);


    // States
    localparam IDLE = 4'b0000;
    localparam READ_FEATURE_HEADER = 4'b0001;
    localparam READ_NUM_RECTS = 4'b0010;
    localparam READ_RECT = 4'b0011;
    localparam QUERY_SUM = 4'b0100;
    localparam ACCUMULATE = 4'b0101;
    localparam DONE_STATE = 4'b0110;
    
    reg [3:0] state;
    reg [3:0] num_rects;          // Number of rectangles in this feature
    reg [3:0] rect_counter;       // Current rectangle being processed
    reg [16:0] base_addr;         // Base address of this feature in ROM
    reg [16:0] rect_data_addr;    // Address for rectangle data
    
    // Rectangle data
    reg [15:0] rect_x, rect_y, rect_w, rect_h;
    reg signed [DATA_WIDTH-1:0] rect_weight;
    
    // Accumulator for feature value
    reg signed [DATA_WIDTH-1:0] accumulator;
    reg [2:0] read_step;          // Step for reading 5 values per rectangle
    

    reg signed [63:0] product;
    reg signed [DATA_WIDTH-1:0] scaled_product;
    reg signed [DATA_WIDTH-1:0] extended_rect_sum;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            feature_value <= 0;
            query_valid <= 0;
            num_rects <= 0;
            rect_counter <= 0;
            accumulator <= 0;
            read_step <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= READ_FEATURE_HEADER;
                        accumulator <= 0;
                        rect_counter <= 0;
                        feature_addr <= feature_index; // The index is the address in the LUT
                    end
                end
                
                READ_FEATURE_HEADER: begin
                    // The first word of the feature is the number of rectangles
                    num_rects <= feature_data[3:0];
                    state <= READ_RECT;
                    read_step <= 0;
                    rect_data_addr <= feature_index + 1; // Start reading rects from the next address
                    feature_addr <= feature_index + 1;
                end

                READ_RECT: begin
                    // Read rectangle data: x, y, w, h, weight (5 lines)
                    case (read_step)
                        0: begin
                            rect_x <= feature_data[15:0];
                            feature_addr <= rect_data_addr + 1;
                            read_step <= 1;
                        end
                        1: begin
                            rect_y <= feature_data[15:0];
                            feature_addr <= rect_data_addr + 2;
                            read_step <= 2;
                        end
                        2: begin
                            rect_w <= feature_data[15:0];
                            feature_addr <= rect_data_addr + 3;
                            read_step <= 3;
                        end
                        3: begin
                            rect_h <= feature_data[15:0];
                            feature_addr <= rect_data_addr + 4;
                            read_step <= 4;
                        end
                        4: begin
                            rect_weight <= feature_data;  // Weight is a fixed-point value
                            state <= QUERY_SUM;
                            read_step <= 0;
                        end
                    endcase
                end
                
                QUERY_SUM: begin
                    // Query integral image for rectangle sum
                    // Scale rectangle coordinates by window position and scale
                    query_x1 <= window_x + ((rect_x * window_scale) >> 8);
                    query_y1 <= window_y + ((rect_y * window_scale) >> 8);
                    query_x2 <= window_x + (((rect_x + rect_w) * window_scale) >> 8) - 1;
                    query_y2 <= window_y + (((rect_y + rect_h) * window_scale) >> 8) - 1;
                    
                    if (rect_sum_valid) begin
                        query_valid <= 0;
                        extended_rect_sum <= rect_sum; // Latch the result
                        state <= ACCUMULATE;
                    end else begin
                        query_valid <= 1;  // Keep query_valid HIGH while waiting
                    end
                end
                
                ACCUMULATE: begin
                    // Calculate feature value using latched sum
                    // Accumulate: feature_value += rect_sum * weight
                    // Perform fixed-point multiplication
                    
                    // Note: extended_rect_sum is already latched in previous state
                    product = extended_rect_sum * rect_weight;
                    
                    // Scale back by fractional bits
                    scaled_product = product >> FIXED_POINT_FRAC;
                    
                    accumulator <= accumulator + scaled_product;
                    
                    // Move to next rectangle
                    rect_counter <= rect_counter + 1;
                    if (rect_counter + 1 >= num_rects) begin
                        state <= DONE_STATE;
                    end else begin
                        state <= READ_RECT;
                        rect_data_addr <= rect_data_addr + 5;
                        feature_addr <= rect_data_addr + 5;
                    end
                end
                
                DONE_STATE: begin
                    feature_value <= accumulator;
                    done <= 1;
                    state <= IDLE;
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
            $display("[FC] Time: %t | State: %d | Rect: %d/%d | QV: %d | RSV: %d", 
                     $time, state, rect_counter, num_rects, query_valid, rect_sum_valid);
            prev_state <= state;
        end
    end

endmodule
