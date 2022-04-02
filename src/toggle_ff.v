// A simple toggle flipflop
module toggle_ff (
    input clk_in,

    input toggle_in,
    output reg r_q_out
);
  initial r_q_out = 1'b0;

  always @(posedge clk_in) begin
    if (toggle_in) begin
      r_q_out <= !r_q_out;
    end
  end
endmodule
