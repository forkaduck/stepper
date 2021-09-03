module debounce (
    input clk_in,
    input in,
    output reg out
);

  reg r_slowclock;

  // btn debouncer
  clk_divider #(
      .SIZE(8)
  ) clk_divider1 (
      .clk_in (clk_in),
      .max_in (8'd250),
      .clk_out(r_slowclock)
  );

  reg r_state1;
  always @(posedge r_slowclock) begin
    r_state1 <= ~in;
    out <= r_state1;
  end
endmodule
