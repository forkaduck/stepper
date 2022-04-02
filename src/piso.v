// Converts parallel data into serial data
// If load_in is high, the value of data_in is loaded
// into the internal shift register.
// In the load cycle no shift is performed.
module piso #(
    parameter SIZE = 8
) (
    input clk_in,
    input en_in,
    input load_in,

    // Parallel data in
    input [SIZE - 1:0] data_in,

    // Serial data out
    output data_out
);

  reg [SIZE - 1:0] r_data;
  assign data_out = r_data[SIZE-1];

  initial r_data = 'b0;

  always @(posedge clk_in) begin
    if (en_in) begin
      if (load_in) begin
        r_data <= data_in;
      end else begin
        r_data <= r_data << 1;
        $display("%m>\tr_data:%b load_in:%x", r_data, load_in);
      end
    end
  end
endmodule
