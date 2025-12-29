// weak_classifier.v
// Evaluates a single weak classifier
// Compares feature value to threshold and returns left_val or right_val

module weak_classifier #(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input start,                                    // Start evaluation
    input signed [DATA_WIDTH-1:0] feature_value,    // Computed feature value
    input signed [DATA_WIDTH-1:0] threshold,        // Classifier threshold
    input signed [DATA_WIDTH-1:0] left_val,         // Value if feature < threshold
    input signed [DATA_WIDTH-1:0] right_val,        // Value if feature >= threshold
    
    output reg signed [DATA_WIDTH-1:0] classifier_output,  // Result
    output reg done
);

    // Simple comparison - one cycle operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            classifier_output <= 0;
            done <= 0;
        end else if (start) begin
            // Decision tree evaluation
            if (feature_value < threshold) begin
                classifier_output <= left_val;
            end else begin
                classifier_output <= right_val;
            end
            done <= 1;
        end else begin
            done <= 0;
        end
    end

endmodule
