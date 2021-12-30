// Originally from https://github.com/freecores/verilog_fixed_point_math_library

module fx_add #(
    //Parameterized value
    parameter Q = 15,
    parameter N = 32
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] c
);

  reg [N-1:0] res;

  assign c = res;

  always @(a, b) begin
    // Both negative or both positive
    // Since they have the same sign, absolute magnitude increases
    if (a[N-1] == b[N-1]) begin
      // So we just add the two numbers and set the sign appropriately.
      // Doesn't matter which one we use, they both have the same sign.
      res[N-2:0] = a[N-2:0] + b[N-2:0];

      // Do the sign last, on the off-chance there was an overflow.
      res[N-1]   = a[N-1];
    end else begin
      // One of them is negative...
      if (a[N-1] == 0 && b[N-1] == 1) begin
        // Subtract a-b
        if (a[N-2:0] > b[N-2:0]) begin
          // If a is greater than b, then just subtract b from a
          // and manually set the sign to positive.
          res[N-2:0] = a[N-2:0] - b[N-2:0];
          res[N-1]   = 0;

        end else begin
          // If a is less than b,
          // we'll actually subtract a from b to avoid a 2's complement
          // answer.
          res[N-2:0] = b[N-2:0] - a[N-2:0];

          // Avoid negative 0 by unsetting the last bit.
          if (res[N-2:0] == 0) begin
            res[N-1] = 0;
          end else begin
            res[N-1] = 1;
          end

        end
      end else begin
        // Subtract b-a (a negative, b positive)
        if (a[N-2:0] > b[N-2:0]) begin
          // If a is greater than b,
          // we'll actually subtract b from a to avoid a 2's complement answer
          // and manually set the sign to negative
          res[N-2:0] = a[N-2:0] - b[N-2:0];

          if (res[N-2:0] == 0) begin
            res[N-1] = 0;
          end else begin
            res[N-1] = 1;
          end
        end else begin
          //If a is less than b, then just subtract a from b
          //and manually set the sign to positive
          res[N-2:0] = b[N-2:0] - a[N-2:0];
          res[N-1]   = 0;
        end
      end
    end
  end
endmodule
