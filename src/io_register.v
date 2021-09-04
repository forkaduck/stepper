module io_register #(
    parameter DATA_WIDTH = 32
) (
    input clk_in,

    // port
    input enable,
    input write,
    input [DATA_WIDTH - 1:0] data_in,
    output [DATA_WIDTH - 1:0] r_data_out,

    output reg [DATA_WIDTH - 1:0] r_mem
);
  reg [DATA_WIDTH - 1:0] r_temp;

  initial begin
    r_mem = 'b0;
  end

  // handle high impedance
  assign r_data_out = enable ? r_temp : 'bz;

  always @(posedge clk_in) begin
    if (enable) begin
      if (write) begin
        r_mem <= data_in;
      end else begin
        r_temp <= r_mem;
      end
    end
  end
endmodule
