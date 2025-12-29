// integral_image.v
// Computes and stores the integral image for fast rectangle sum calculation
// Integral image: I(x,y) = sum of all pixels at (x',y') where x'<=x and y'<=y

module integral_image #(
    parameter IMG_WIDTH = 64,   // Image width
    parameter IMG_HEIGHT = 64,  // Image height
    parameter PIXEL_WIDTH = 8,  // Input pixel bit width
    parameter SUM_WIDTH = 24    // Integral image accumulator width
)(
    input clk,
    input rst,
    input start,                           // Start computing integral image
    input [PIXEL_WIDTH-1:0] pixel_in,      // Input pixel value
    input pixel_valid,                     // Pixel input valid
    
    // Outputs for rectangle sum queries
    input [15:0] query_x1, query_y1,       // Top-left corner
    input [15:0] query_x2, query_y2,       // Bottom-right corner
    input query_valid,                     // Query request
    output reg [SUM_WIDTH-1:0] rect_sum,   // Rectangle sum result
    output reg rect_sum_valid,             // Result valid
    
    output reg done                        // Integral image computation done
);

    // Integral image storage (RAM)
    reg [SUM_WIDTH-1:0] integral_img [0:IMG_HEIGHT-1][0:IMG_WIDTH-1];
    
    // Computation state machine
    reg [7:0] x_pos, y_pos;
    reg computing;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam READY = 2'b10;
    
    reg [1:0] state;
    
    // Intermediate values for integral image calculation
    reg [SUM_WIDTH-1:0] current_sum;
    reg [SUM_WIDTH-1:0] above_sum;
    reg [SUM_WIDTH-1:0] left_sum;
    reg [SUM_WIDTH-1:0] diag_sum;
    
    // State machine for integral image computation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            x_pos <= 0;
            y_pos <= 0;
            done <= 0;
            computing <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= COMPUTE;
                        x_pos <= 0;
                        y_pos <= 0;
                        computing <= 1;
                        // Initialize first pixel
                        integral_img[0][0] <= 0;
                    end
                end
                
                COMPUTE: begin
                    if (pixel_valid) begin
                        // Calculate integral image value
                        // I(x,y) = pixel(x,y) + I(x-1,y) + I(x,y-1) - I(x-1,y-1)
                        
                        if (x_pos == 0 && y_pos == 0) begin
                            integral_img[y_pos][x_pos] <= pixel_in;
                        end else if (x_pos == 0) begin
                            integral_img[y_pos][x_pos] <= pixel_in + integral_img[y_pos-1][x_pos];
                        end else if (y_pos == 0) begin
                            integral_img[y_pos][x_pos] <= pixel_in + integral_img[y_pos][x_pos-1];
                        end else begin
                            integral_img[y_pos][x_pos] <= pixel_in + 
                                                          integral_img[y_pos][x_pos-1] + 
                                                          integral_img[y_pos-1][x_pos] - 
                                                          integral_img[y_pos-1][x_pos-1];
                        end
                        
                        // Move to next pixel
                        if (x_pos == IMG_WIDTH - 1) begin
                            x_pos <= 0;
                            if (y_pos == IMG_HEIGHT - 1) begin
                                state <= READY;
                                done <= 1;
                                computing <= 0;
                            end else begin
                                y_pos <= y_pos + 1;
                            end
                        end else begin
                            x_pos <= x_pos + 1;
                        end
                    end
                end
                
                READY: begin
                    done <= 1;
                    if (start) begin
                        state <= COMPUTE;
                        x_pos <= 0;
                        y_pos <= 0;
                        done <= 0;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Rectangle sum query using integral image
    // Sum(x1,y1,x2,y2) = I(x2,y2) - I(x1-1,y2) - I(x2,y1-1) + I(x1-1,y1-1)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rect_sum <= 0;
            rect_sum_valid <= 0;
        end else if (query_valid && state == READY) begin
            // Boundary checks and integral image formula
            if (query_x1 == 0 && query_y1 == 0) begin
                rect_sum <= integral_img[query_y2][query_x2];
            end else if (query_x1 == 0) begin
                rect_sum <= integral_img[query_y2][query_x2] - 
                           integral_img[query_y1-1][query_x2];
            end else if (query_y1 == 0) begin
                rect_sum <= integral_img[query_y2][query_x2] - 
                           integral_img[query_y2][query_x1-1];
            end else begin
                rect_sum <= integral_img[query_y2][query_x2] - 
                           integral_img[query_y1-1][query_x2] - 
                           integral_img[query_y2][query_x1-1] + 
                           integral_img[query_y1-1][query_x1-1];
            end
            rect_sum_valid <= 1;
        end else begin
            rect_sum_valid <= 0;
        end
    end

endmodule
