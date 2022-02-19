
module pythagoras #(
    parameter Q = 15,
    parameter N = 32
) (
    input [N-1:0] x_in,
    input [N-1:0] y_in,

    output [N-1:0] len_out,
    output overflow
);

  wire [N-1:0] x_power_two;
  wire x_overflow;

  wire [N-1:0] y_power_two;
  wire y_overflow;

  assign overflow = y_overflow || x_overflow;

  // x_power_two = x^2
  fx_mult #(
      .Q(Q),
      .N(N)
  ) calc_x_power (
      .multiplicand_in(x_in),
      .multiplier_in(x_in),
      .r_result_out(x_power_two),
      .overflow_r_out(x_overflow)
  );

  // y_power_two = y^2
  fx_mult #(
      .Q(Q),
      .N(N)
  ) calc_y_power (
      .multiplicand_in(y_in),
      .multiplier_in(y_in),
      .r_result_out(y_power_two),
      .overflow_r_out(y_overflow)
  );

  // len_out = x_power_two + y_power_two
  fx_add #(
      .Q(Q),
      .N(N)
  ) calc_x_y_add (
      .summand_a_in(x_power_two),
      .summand_b_in(y_power_two),
      .sum_out(len_out)
  );

endmodule
