// Convert serial into parallel data.
module sipo #(
    parameter SIZE = 8
) (
    input data_in,
    input clk_in,
    input en_in,
    output [SIZE - 1:0] data_out
);

  reg [SIZE - 1:0] r_data_out = {SIZE{1'b0}};

  assign data_out = r_data_out;

  always @(posedge clk_in) begin
    if (en_in) begin
      r_data_out <= {r_data_out[SIZE-2:0], data_in};
      $display("%m>\tdata_in:%x r_data_out:%b", data_in, r_data_out);
    end
  end
endmodule
