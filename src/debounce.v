module debounce (
    input clk_in,
    input in,
    output reg out
);

  reg  r_clk_buff;
  wire r_slowclock;

  initial begin
    out = 'b0;
  end

  // btn debouncer
  clk_divider #(
      .SIZE(8)
  ) clk_divider1 (
      .clk_in (clk_in),
      .max_in (8'd250),
      .clk_out(r_slowclock)
  );

  always @(posedge r_slowclock) begin
    r_clk_buff <= ~in;
    out <= r_clk_buff;
  end
endmodule
