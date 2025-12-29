// haar_cascade_rom.v
// ROM for storing the Haar cascade data
// Initialized with data from cascade_data.mem

module haar_cascade_rom #(
    parameter ADDR_WIDTH = 17,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 131072,
    parameter MEM_FILE = "../data/cascade_data.mem"
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
