// Adds two fixed point values together.
// Originally from https://github.com/freecoresult/verilog_fixed_point_math_library
// Modified to be readable
module fx_add #(
    parameter Q = 15,
    parameter N = 32
) (
    // Numbers
    input  [N-1:0] summand_a_in,
    input  [N-1:0] summand_b_in,
    output [N-1:0] sum_out
);

  reg [N-1:0] result;

  assign sum_out = result;

  always @(summand_a_in, summand_b_in) begin
    // Both negative or both positive
    // Since they have the same sign, absolute magnitude increases
    if (summand_a_in[N-1] == summand_b_in[N-1]) begin
      // So we just add the two numbers and set the sign appropriately.
      // Doesn't matter which one we use, they both have the same sign.
      result[N-2:0] = summand_a_in[N-2:0] + summand_b_in[N-2:0];

      // Do the sign last, on the off-chance there was an overflow.
      result[N-1]   = summand_a_in[N-1];
    end else begin
      // One of them is negative
      if (summand_a_in[N-1] == 0 && summand_b_in[N-1] == 1) begin
        // Subtract a-b
        if (summand_a_in[N-2:0] > summand_b_in[N-2:0]) begin
          // If summand_a_in is greater than b, then just subtract b from a
          // and manually set the sign to positive.
          result[N-2:0] = summand_a_in[N-2:0] - summand_b_in[N-2:0];
          result[N-1]   = 0;

        end else begin
          // If a is less than b,
          // we'll actually subtract a from b to avoid a 2's complement
          // answer.
          result[N-2:0] = summand_b_in[N-2:0] - summand_a_in[N-2:0];

          // Avoid negative 0 by unsetting the last bit.
          if (result[N-2:0] == 0) begin
            result[N-1] = 0;
          end else begin
            result[N-1] = 1;
          end

        end
      end else begin
        // Subtract b-a (a negative, b positive)
        if (summand_a_in[N-2:0] > summand_b_in[N-2:0]) begin
          // If a is greater than b,
          // we'll actually subtract b from a to avoid a 2's complement answer
          // and manually set the sign to negative
          result[N-2:0] = summand_a_in[N-2:0] - summand_b_in[N-2:0];

          if (result[N-2:0] == 0) begin
            result[N-1] = 0;
          end else begin
            result[N-1] = 1;
          end
        end else begin
          //If a is less than b, then just subtract a from b
          //and manually set the sign to positive
          result[N-2:0] = summand_b_in[N-2:0] - summand_a_in[N-2:0];
          result[N-1]   = 0;
        end
      end
    end
  end
endmodule
