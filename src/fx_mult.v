// Originally from https://github.com/freecores/verilog_fixed_point_math_library
// Modified to be readable

module fx_mult #(
    parameter Q = 15,
    parameter N = 32
) (
    input  [N-1:0] multiplicand_i,
    input  [N-1:0] multiplier_i,
    output [N-1:0] result_o,

    output reg overflow_r_o
);

  // The underlying assumption, here, is that both fixed-point values are of the same length (N,Q)
  // Because of this, the results will be of length N+N = 2N bits
  // This also simplifies the hand-back of results, as the binimal point will always be in the same location.

  // Multiplication by 2 values of N bits requires a
  reg [2*N-1:0] r_result;

  // Register that is N+N = 2N deep
  reg [  N-1:0] r_RetVal;

  // Only handing back the same number of bits as we received with fixed point in same location
  assign result_o = r_RetVal;

  always @(multiplicand_i, multiplier_i) begin
    // Do the multiply any time the inputs change
    // Removing the sign bits from the multiply (that would introduce *big* errors)
    r_result <= multiplicand_i[N-2:0] * multiplier_i[N-2:0];
    overflow_r_o <= 1'b0;
  end

  // This always block will throw a warning, as it uses a & b, but only acts on changes in result
  always @(r_result) begin
    // Any time the result changes, we need to recompute the sign bit,
    // which is the XOR of the input sign bits  (you do the truth table)
    r_RetVal[N-1]   <= multiplicand_i[N-1] ^ multiplier_i[N-1];

    // And we also need to push the proper N bits of result up to the calling
    // entity
    r_RetVal[N-2:0] <= r_result[N-2+Q:Q];

    if (r_result[2*N-2:N-1+Q] > 0) begin
      // Check for an overflow
      overflow_r_o <= 1'b1;
    end
  end
endmodule
