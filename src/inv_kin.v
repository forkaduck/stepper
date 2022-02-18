
module inv_kin #(
    parameter Q = 15,
    parameter N = 32
) (
    input clk_in,
    input [N -1:0] x_in,
    input [N -1:0] y_in,
    input [N -1:0] z_in,

    output [N -1:0] one_out,
    output [N -1:0] sec_out,
    output [N -1:0] third_out
);

  read_func #(
`ifdef __ICARUS__
      .PATH("../math_functions/arccos.mem"),
`else
      .PATH("math_functions/arccos.mem"),
`endif
      .DATA_SIZE(200),
      .DATA_WIDTH(32)
  ) arccos (
      .x_in (x_in),
      .y_out(one_out)
  );

endmodule
