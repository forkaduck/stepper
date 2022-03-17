
module inv_kin #(
    parameter Q = 32,
    parameter N = 64,

    parameter UPPER_HIP_LEN   = 10,
    parameter UPPER_THIGH_LEN = 10,
    parameter LOWER_THIGH_LEN = 10
) (
    input clk_in,
    input [N -1:0] x_in,
    input [N -1:0] y_in,
    input [N -1:0] z_in,

    output [N -1:0] alpha_out,
    output [N -1:0] beta_out,
    output [N -1:0] gamma_out
);

  // Calculate the angle alpha (the hip joint)
  wire [N-1:0] alpha_pyth;
  pythagoras #(
      .Q(Q),
      .N(N)
  ) calc_alpha_pyth (
      .clk_in(clk_in),
      .x_in  (x_in),
      .y_in  (y_in),

      .len_out(alpha_pyth),
      .overflow_out(),
      .valid_out()
  );

  wire [N-1:0] alpha_div;
  fx_div #(
      .Q(Q),
      .N(N)
  ) calc_alpha_div (
      .dividend_in (x_in),
      .divisor_in  (alpha_pyth),
      .quotient_out(alpha_div),

      .start_in(1'b1),
      .clk_in  (clk_in),

      .complete_out(),
      .overflow_out()
  );

  read_func #(
`ifdef __ICARUS__
      .PATH("../math_functions/arccos.mem"),
`else
      .PATH("math_functions/arccos.mem"),
`endif
      .DATA_SIZE(200),
      .DATA_WIDTH(N)
  ) arccos (
      .x_in (alpha_div >> Q),  // shift??
      .y_out(alpha_out)
  );

endmodule
