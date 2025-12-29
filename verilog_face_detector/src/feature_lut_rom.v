// feature_lut_rom.v
// ROM for storing the feature lookup table
// Initialized with data from feature_lut.mem

module feature_lut_rom #(
    parameter ADDR_WIDTH = 17,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 131072,
    parameter MEM_FILE = "../data/feature_lut.mem"
)(
    input clk,
    input [ADDR_WIDTH-1:0] address,
    output reg [DATA_WIDTH-1:0] data
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    initial begin
        $readmemh(MEM_FILE, mem);
    end

    always @(posedge clk) begin
        data <= mem[address];
    end

endmodule