// convert serial into parallel data
module sipo #(
    parameter integer SIZE = 8
) (
    input data_in,
    input clk_in,
    input reset_n_in,
    output reg [SIZE - 1:0] r_data_out
);

  initial r_data_out = 'b0;

  always @(posedge clk_in, negedge reset_n_in) begin
    if (!reset_n_in) begin
      r_data_out <= 'b0;
    end else begin
      r_data_out <= {data_in, r_data_out[SIZE-1:1]};
    end
    $display("%m>\tdata_in:%x r_data_out:%b", data_in, r_data_out);
  end
endmodule
