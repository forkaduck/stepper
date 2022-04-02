// Reads a math function previously generated
// earlier in the workflow into blockram
module read_func #(
    // The Path to the data file in standard readmemh format
    parameter PATH = "",

    // Blockram width and height
    parameter DATA_SIZE  = 1024,
    parameter DATA_WIDTH = 32
) (
    // In/Output wires (y(x) = ?)
    input  [DATA_WIDTH -1 : 0] x_in,
    output [DATA_WIDTH -1 : 0] y_out
);

  reg [DATA_WIDTH -1 : 0] r_table[DATA_SIZE -1 : 0];

  initial begin
    $readmemh(PATH, r_table, 0, DATA_SIZE - 1);
  end

  assign y_out = r_table[x_in];

endmodule
