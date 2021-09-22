// Register to hold one 32bit value. Can be
// configured to drive some external signals.
module io_register #(
    parameter DATA_WIDTH = 32
) (
    input clk_in,

    // port
    input enable,
    input write,
    output reg ready,

    // port
    input [DATA_WIDTH - 1:0] data_in,
    output reg [DATA_WIDTH - 1:0] r_data_out,

    output reg [DATA_WIDTH - 1:0] r_mem
);
  initial begin
    ready = 1'bz;
    r_data_out = 'bz;
    r_mem = 'b0;
  end

  always @(posedge clk_in) begin
    if (enable) begin
      if (write) begin
        r_mem <= data_in;
        r_data_out <= 'bz;
      end

      r_data_out <= r_mem;
      ready <= 1'b1;
    end else begin
      r_data_out <= 'bz;
      ready <= 1'bz;
    end
  end
endmodule
