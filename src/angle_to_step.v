// All floating point parameters are 12.4
// notation (GEARUP, STEPANGLE)
module angle_to_step #(
    parameter MICROSTEPS = 256,
    parameter STEPANGLE = 1.8,
    parameter GEARUP = 26.85,

    parameter SYSCLK = 25000000,
    parameter SIZE = 64,
    parameter VRISE = 20000.0,
    parameter TRISE = 100.0,
    parameter VOFFSET = 3000.0
) (
    input clk_i,
    input reset_n_i,

    input enable_i,
    input [31:0] relative_angle_i,
    output step_o
);
  parameter JERCK = (4.0 * VRISE / $pow(TRISE, 2.0));

  wire int_clk;
  wire output_clk;

  assign step_o = enable_i ? output_clk : 1'b0;

  reg [SIZE - 1:0] r_div = {SIZE{1'b0}};
  reg [SIZE - 1:0] r_t = {SIZE{1'b0}} | 1'b1;

  reg [1:0] ding = 0;

  // Internal clk
  clk_divider #(
      .SIZE(32)
  ) internal (
      .clk_in (clk_i),
      // Every 1 us
      .max_in ((SYSCLK / 25000.0) / 2),
      .clk_out(int_clk)
  );

  // Output clk divider
  clk_divider #(
      .SIZE(SIZE)
  ) div (
      .clk_in (clk_i),
      .max_in (VRISE - r_div + VOFFSET),
      .clk_out(output_clk)
  );

  // Update the clkdivider output every int_clk
  always @(posedge int_clk, negedge reset_n_i) begin
    if (!reset_n_i) begin
      r_t <= 1.0;
    end else begin
      if (r_t > 0 && r_t < (TRISE / 2)) begin
        // Wenn(x < t_{rise} / 2 ∧ x > 0, 1 / 2 J x²)
        r_div = 0.5 * JERCK * $pow(r_t, 2.0);
        ding <= 1;

      end else if (r_t >= (TRISE / 2) && r_t < TRISE) begin
        // Wenn(t_{rise} / 2 ≤ x ∧ x < t_{rise}, 1 / 4 J (4x t_{rise} - 2x² - t_{rise}²))
        r_div = 0.25 * JERCK * (r_t * 4.0 * TRISE - 2.0 * $pow(r_t, 2.0) - $pow(TRISE, 2.0));
        ding <= 2;

      end else if (r_t >= TRISE) begin
        r_div = (VRISE);
        ding <= 3;

      end

      r_t <= r_t + 1.0;
    end
  end
endmodule
