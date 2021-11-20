// All floating point parameters are 12.4
// notation (GEARUP, STEPANGLE)
module angle_to_step #(
    parameter MICROSTEPS = 256,
    parameter STEPANGLE = 1.8,
    parameter GEARUP = 26.85,

    parameter SYSCLK = 25000000,
    parameter DIVMAX = 32,
    parameter SIZE   = 64,
    parameter VRISE  = 250,
    parameter TRISE  = 2500
) (
    input clk_i,
    input reset_n_i,

    input enable_i,
    input [31:0] relative_angle_i,
    output step_o
);
  parameter FFIX = 2;
  parameter SHIFT_VRISE = VRISE << FFIX;
  parameter SHIFT_TRISE = TRISE << FFIX;

  parameter JERCK = (4 * SHIFT_VRISE / SHIFT_TRISE ^ 2);

  wire int_clk;
  wire output_clk;

  assign step_o = enable_i ? output_clk : 1'b0;

  reg [SIZE - 1:0] r_div = {SIZE{1'b0}};
  reg [SIZE - 1:0] r_t = {SIZE{1'b0}} | 1'b1;

  // Internal clk
  clk_divider #(
      .SIZE(32)
  ) internal (
      .clk_in (clk_i),
      // Every 1 us
      .max_in (SYSCLK / 1000000),
      .clk_out(int_clk)
  );

  // Output clk divider
  clk_divider #(
      .SIZE(SIZE)
  ) div (
      .clk_in (clk_i),
      .max_in (VRISE - (r_div >> FFIX)),
      .clk_out(output_clk)
  );

  // Update the clkdivider output every int_clk
  always @(posedge int_clk, negedge reset_n_i) begin
    if (!reset_n_i) begin
      r_t <= 1;
    end else begin
      if (r_t > 0 && r_t < TRISE / 2) begin
        r_div = 2 * JERCK * $pow(r_t, 2);

      end else if (r_t >= TRISE / 2 && r_t <= TRISE) begin
        r_div = 1 * JERCK * (4 * r_t * SHIFT_TRISE - 2 * $pow(r_t, 2) - $pow(SHIFT_TRISE, 2));

      end else if (r_t > TRISE) begin
        r_div = VRISE;

      end

      r_t <= r_t + 1;
    end
  end
endmodule
