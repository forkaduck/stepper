module pythagoras #(
    parameter Q = 32,
    parameter N = 64
) (
    input clk_in,
    input [N-1:0] x_in,
    input [N-1:0] y_in,

    output [N-1:0] len_out,
    output overflow_out,
    output valid_out
);


  wire [N-1:0] x_power_two;
  wire x_overflow;

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

  wire [N-1:0] y_power_two;
  wire y_overflow;

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

  wire [N-1:0] x_y_add;

  // len_out = x_power_two + y_power_two
  fx_add #(
      .Q(Q),
      .N(N)
  ) calc_x_y_add (
      .summand_a_in(x_power_two),
      .summand_b_in(y_power_two),
      .sum_out(x_y_add)
  );

  assign overflow_out = y_overflow || x_overflow;

  read_func #(
`ifdef __ICARUS__
      .PATH("../math_functions/sqrt.mem"),
`else
      .PATH("math_functions/sqrt.mem"),
`endif
      .DATA_SIZE(200),
      .DATA_WIDTH(N)
  ) calc_x_y_sqrt (
      .x_in (x_y_add >> Q),
      .y_out(len_out)
  );
endmodule
