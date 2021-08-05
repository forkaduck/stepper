
module toggle_ff (
    input clk_in,
    input toggle_in,
    output reg q_out
);
  always @(posedge clk_in) begin
    if (toggle_in) begin
      q_out <= !q_out;
    end
  end
endmodule
