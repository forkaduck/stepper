
module read_func #(
    parameter PATH = "",
    parameter DATA_SIZE = 1024,
    parameter DATA_WIDTH = 32
) (
    input  [DATA_WIDTH -1 : 0] x_in,
    output [DATA_WIDTH -1 : 0] y_out
);

  reg [DATA_WIDTH -1 : 0] r_table[DATA_SIZE -1 : 0];

  initial begin
    $readmemh(PATH, r_table, 0, DATA_SIZE - 1);
  end

  assign y_out = r_table[x_in];

endmodule
