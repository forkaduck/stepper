// Register to hold one 32bit value. Can be
// configured to drive some external signals.
module io_register_output #(
    parameter DATA_WIDTH = 32
) (
    input clk_in,

    // port
    input  enable_in,
    input  write_in,
    output ready_out,

    // port
    input  [DATA_WIDTH - 1:0] data_in,
    output [DATA_WIDTH - 1:0] data_out,

    output [DATA_WIDTH - 1:0] mem_out
);
  reg [DATA_WIDTH - 1:0] r_mem;

  assign mem_out = r_mem;

  initial begin
    r_mem = {DATA_WIDTH{1'b0}};
  end

  always @(posedge clk_in) begin
    if (write_in & enable_in) begin
      r_mem <= data_in;
    end
  end

  assign ready_out = enable_in ? 1'b1 : 1'bz;
  assign data_out  = (enable_in && !write_in) ? r_mem : {DATA_WIDTH{1'bz}};
endmodule
