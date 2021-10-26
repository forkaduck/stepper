// Register to hold one 32bit value. Can be
// configured to drive some external signals.
module io_register_output #(
    parameter DATA_WIDTH = 32
) (
    input clk_in,

    // port
    input  enable,
    input  write,
    output ready,

    // port
    input  [DATA_WIDTH - 1:0] data_in,
    output [DATA_WIDTH - 1:0] data_out,

    inout [DATA_WIDTH - 1:0] mem
);
  initial begin
    r_mem = 'b0;
  end

  assign mem = r_mem;

  reg [DATA_WIDTH - 1: 0] r_mem;

  always @(posedge clk_in) begin
    if (write & enable) begin
      r_mem <= data_in;
    end
  end

  assign ready = enable ? 1'b1 : 1'bz;
  assign data_out = enable ? r_mem : 'bz;
endmodule
