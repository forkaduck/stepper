module angle_to_step #(
    parameter SIZE = 64,
    // MICROSTEPS / (STEPANGLE / GEARING)
    // (in Q(SIZE >> 1).(SIZE>>1))
    parameter [SIZE - 1 : 0] SCALE = {32'd4103, {(SIZE >> 1) {1'b0}}},

    parameter SYSCLK = 25000000,
    parameter integer VRISE = 20000,
    parameter integer TRISE = 10000,
    parameter integer VOFFSET = 6000
) (
    input clk_i,

    input enable_i,
    output reg done_o = 1'b0,

    input [SIZE - 1:0] relative_angle_i,
    output step_o
);
  parameter [SIZE - 1:0] SPEEDUP = VRISE / TRISE;

  wire int_clk;
  wire output_clk;

  // Used as the actual frequency divider (inverse)
  reg [SIZE - 1:0] r_div = 1'b0;

  reg [SIZE - 1:0] r_t = 1'b1;

  reg r_enable_prev = 1'b0;
  reg r_run = 1'b0;

  reg [SIZE - 1:0] steps_done = 0;
  wire [SIZE - 1:0] steps_needed;

  assign step_o = (r_t > 1) ? output_clk : 1'b0;

  always @(posedge clk_i) begin
    // Reset on negative edge
    if (!enable_i && r_enable_prev) begin
      r_run  <= 1'b0;
      done_o <= 1'b0;
    end

    if (steps_done >= steps_needed) begin
      r_run  <= 1'b0;
      done_o <= 1'b1;
    end

    // Enable output
    if (enable_i && !r_enable_prev) begin
      r_run  <= 1'b1;
      done_o <= 1'b0;
    end

    r_enable_prev <= enable_i;
  end

  // Counter to keep track of how far the algorithm has already stepped.
  // It is used to find out when the algorithm needs to be reversed for the falloff.
  always @(posedge output_clk) begin
    // Count the steps done up until it reaches steps_done
    if (r_run) begin
      steps_done <= steps_done + {1'b1, {(SIZE >> 1) {1'b0}}};
    end else begin
      steps_done <= 0;
    end
  end

  always @(negedge output_clk) begin
    // Count the steps done up until it reaches steps_done
    if (r_run) begin
      steps_done <= steps_done + {1'b1, {(SIZE >> 1) {1'b0}}};
    end else begin
      steps_done <= 0;
    end
  end

  // Increment time if the output is enabled
  always @(posedge int_clk) begin
    if (r_run) begin
      if ((steps_needed >> 1) <= steps_done) begin
        r_t <= r_t - 1'b1;
      end else begin
        r_t <= r_t + 1'b1;
      end
    end else begin
      r_t <= 1'b1;
    end
  end

  // Update the clkdivider output every int_clk
  always @(posedge clk_i) begin
    if (r_t > 0 && r_t < TRISE) begin
      //First rise
      r_div <= SPEEDUP * r_t;

    end else begin
      // Error
      r_div = VRISE;
    end
  end

  /* steps_needed <= relative_angle_i * SCALE; */
  fx_mult #(
      .Q(SIZE >> 1),
      .N(SIZE)
  ) steps_needed_mult (
      .multiplicand_i(relative_angle_i),
      .multiplier_i(SCALE),
      .r_result_o(steps_needed),
      .overflow_r_o()
  );

  // Internal clk (used for timekeeping)
  clk_divider #(
      .SIZE(32)
  ) internal (
      .clk_in (clk_i),
      // Every 1 us
      .max_in ((SYSCLK / 1000000) / 2),
      .clk_out(int_clk)
  );

  // Step pulse generator clk divider
  clk_divider #(
      .SIZE(SIZE)
  ) div (
      .clk_in (clk_i),
      .max_in ((VRISE - r_div + VOFFSET) / 2),
      .clk_out(output_clk)
  );
endmodule
