// Originally from https://github.com/freecores/verilog_fixed_point_math_library
// Modified to be readable

module fx_mult #(
    parameter Q = 15,
    parameter N = 32
) (
    input [N-1:0] multiplicand_in,
    input [N-1:0] multiplier_in,
    output reg [N-1:0] r_result_out,

    output reg overflow_r_out
);

  // The underlying assumption, here, is that both fixed-point values are of the same length (N,Q)
  // Because of this, the results will be of length N+N = 2N bits
  // This also simplifies the hand-back of results, as the binimal point will always be in the same location.

  // Multiplication by 2 values of N bits requires a register that is N+N = 2N deep
  reg [2*N-1:0] r_result;

  always @(multiplicand_in, multiplier_in) begin
    // Do the multiply any time the inputs change
    // Removing the sign bits from the multiply (that would introduce *big* errors)
    r_result <= multiplicand_in[N-2:0] * multiplier_in[N-2:0];
    overflow_r_out <= 1'b0;
  end

  // This always block will throw a warning, as it uses a & b, but only acts on changes in result
  always @(r_result) begin
    // Any time the result changes, we need to recompute the sign bit,
    // which is the XOR of the input sign bits  (you do the truth table)
    r_result_out[N-1]   <= multiplicand_in[N-1] ^ multiplier_in[N-1];

    // And we also need to push the proper N bits of result up to the calling
    // entity
    r_result_out[N-2:0] <= r_result[N-2+Q:Q];

    if (r_result[2*N-2:N-1+Q] > 0) begin
      // Check for an overflow
      overflow_r_out <= 1'b1;
    end
  end
endmodule
