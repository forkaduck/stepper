// All floating point parameters are 14.2
// notation (GEARUP, STEPANGLE)
module angle_to_step #(
    parameter MICROSTEPS = 256,
    parameter STEPANGLE = 1.80,
    parameter GEARUP = 26.85,

    parameter SYSCLK = 25000000,
    parameter SIZE = 64,
    // 20000
    parameter integer VRISE = 'b0100111000100000_0000,
    // 1000
    parameter integer TRISE = 'b001111101000_0000,
    parameter integer VOFFSET = 'b0001011101110000_0000
) (
    input clk_i,
    input reset_n_i,

    input enable_i,
    input [SIZE - 1:0] relative_angle_i,
    output step_o
);
  parameter JERCK = (4 * VRISE / (TRISE ** 2));
  parameter SF = 4;
  parameter TIME_INC = 5'b1_0000;

  wire int_clk;
  wire output_clk;

  assign step_o = enable_i ? output_clk : 1'b0;

  reg [SIZE - 1:0] r_div = 0;
  reg [SIZE - 1:0] r_t;

  reg count_back = 1'b0;

  reg [SIZE - 1:0] steps_done;
  reg [SIZE - 1:0] steps_needed;

  reg [1:0] state = 1'b0;

  // Internal clk
  clk_divider #(
      .SIZE(32)
  ) internal (
      .clk_in (clk_i),
      // Every 1 us
      .max_in ((SYSCLK / 1000000) / 2),
      .clk_out(int_clk)
  );

  // Output clk divider
  clk_divider #(
      .SIZE(SIZE)
  ) div (
      .clk_in (clk_i),
      .max_in (((VRISE - r_div + VOFFSET) >> SF) / 2),
      .clk_out(output_clk)
  );

  // Update the clkdivider output every int_clk
  always @(posedge int_clk) begin
    if (r_t > 0 && r_t < (TRISE / 2)) begin
      //First rise
      // Wenn(x < t_{rise} / 2 ∧ x > 0, 1 / 2 J x²)
      r_div <= 8 * JERCK * r_t ** 2;
      state <= 1;

    end else if (r_t >= (TRISE / 2) && r_t < TRISE) begin
      // Second rise
      // Wenn(t_{rise} / 2 ≤ x ∧ x < t_{rise}, 1 / 4 J (4x t_{rise} - 2x² - t_{rise}²))
      r_div <= 4 * JERCK * (4 * r_t * TRISE - 2 * (r_t ** 2) - TRISE ** 2);
      state <= 2;

    end else begin
      // Error
      r_div = VRISE;
      state <= 3;
    end
  end

  always @(posedge output_clk, negedge reset_n_i) begin
    if (!reset_n_i) begin
      steps_done <= 0;
    end else begin

      if (steps_needed == steps_done) begin
        steps_done <= 0;
      end else begin
        steps_done <= steps_done + 1;
      end
    end
  end

  always @(posedge int_clk, negedge reset_n_i) begin
    if (!reset_n_i) begin
      r_t <= TIME_INC;
      steps_needed <= 0;
    end else begin
      if (r_t >= TRISE && (steps_needed / 2) <= steps_done) begin
        count_back <= 1'b1;
      end else if (r_t == 0) begin
        count_back <= 1'b0;
      end

      if (enable_i) begin
        if (count_back) begin
          r_t <= r_t - TIME_INC;
        end else begin
          r_t <= r_t + TIME_INC;
        end
      end else begin
        r_t <= TIME_INC;
      end
    end

    steps_needed <= (relative_angle_i * GEARUP) / STEPANGLE * MICROSTEPS;
  end
endmodule
