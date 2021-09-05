module io_register #(
    parameter DATA_WIDTH = 32
) (
    input clk_in,

    // port
    input enable,
    input write,
    input [DATA_WIDTH - 1:0] data_in,
    output reg [DATA_WIDTH - 1:0] r_data_out,

    output reg [DATA_WIDTH - 1:0] r_mem
);
  initial begin
    r_mem = 'b0;
    r_data_out = 'b0;
  end

  always @(posedge clk_in) begin
    if (write) begin
      r_mem <= data_in;
    end else begin
      r_data_out <= enable ? r_mem : 'bz;
    end
  end
endmodule
