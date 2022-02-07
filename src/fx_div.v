// Originally from https://github.com/freecores/verilog_fixed_point_math_library
// Modified to be readable

module fx_div #(
    parameter Q = 15,
    parameter N = 32
) (
    // Numbers
    input [N-1:0] dividend_in,
    input [N-1:0] divisor_in,

    output [N-1:0] quotient_out,

    // Flags
    input start_in,
    input clk_in,

    output complete_out,
    output overflow_out
);
  // Our working copy of the quotient
  reg [2*N+Q-3:0] reg_working_quotient = 0;

  // Final quotient  
  reg [N-1:0] reg_quotient = 0;

  // Working copy of the dividend
  reg [N-2+Q:0] reg_working_dividend = 0;

  // Working copy of the divisor
  reg [2*N+Q-3:0] reg_working_divisor = 0;

  // This is obviously a lot bigger than it needs to be, as we only need 
  // count to N-1+Q but, computing that number of bits requires a 
  // logarithm (base 2), and I don't know how to do that in a 
  // way that will work for everyone
  reg [N-1:0] reg_count = 0;

  //Computation completed flag
  //Initial state is to not be doing anything
  reg reg_done = 1'b1;

  //The quotient's sign bit
  //And the sign should be positive
  reg reg_sign = 1'b0;

  //Overflow flag
  //And there should be no overflow present
  reg reg_overflow = 1'b0;

  //The division results
  assign quotient_out[N-2:0] = reg_quotient[N-2:0];

  //The sign of the quotient
  assign quotient_out[N-1]   = reg_sign;

  assign complete_out        = reg_done;
  assign overflow_out        = reg_overflow;

  always @(posedge clk_in) begin
    if (reg_done && start_in) begin
      //This is our startup condition
      reg_done <= 1'b0;

      //Set the count
      reg_count <= N + Q - 1;

      //Clear out the quotient register
      reg_working_quotient <= 0;

      //Clear out the dividend register
      reg_working_dividend <= 0;

      //Clear out the divisor register 
      reg_working_divisor <= 0;

      //Clear the overflow register
      reg_overflow <= 1'b0;

      //Left-align the dividend in its working register
      reg_working_dividend[N+Q-2:Q] <= dividend_in[N-2:0];

      //Left-align the divisor into its working register
      reg_working_divisor[2*N+Q-3:N+Q-1] <= divisor_in[N-2:0];

      //Set the sign bit
      reg_sign <= dividend_in[N-1] ^ divisor_in[N-1];

    end else if (!reg_done) begin
      //Right shift the divisor (that is, divide it by two - aka reduce the divisor)
      reg_working_divisor <= reg_working_divisor >> 1;

      //Decrement the count
      reg_count <= reg_count - 1;

      if (reg_working_dividend >= reg_working_divisor) begin
        //If the dividend is greater than the divisor
        //Set the quotient bit
        reg_working_quotient[reg_count] <= 1'b1;

        //and subtract the divisor from the dividend
        reg_working_dividend <= reg_working_dividend - reg_working_divisor;
      end

      if (reg_count == 0) begin
        //stop condition
        //If we're done, it's time to tell the calling process
        reg_done     <= 1'b1;

        //Move in our working copy to the outside world
        reg_quotient <= reg_working_quotient;

        if (reg_working_quotient[2*N+Q-3:N] > 0) begin
          reg_overflow <= 1'b1;
        end else begin
          reg_count <= reg_count - 1;
        end
      end
    end
  end
endmodule
