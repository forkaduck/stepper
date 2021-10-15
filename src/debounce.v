// Button debouncer adds about 20us to
// the signal in question.
module debounce (
    input clk_in,
    input in,
    output reg r_out
);
  parameter MAX_VAL = 2000;
  reg [$clog2(MAX_VAL):0] r_counter;
  reg r_prev_in;

  initial begin
    r_counter = 'b0;
    r_out = 'b0;
    r_prev_in = 'b0;
  end

  always @(posedge clk_in) begin
    if (r_counter >= MAX_VAL) begin
      r_counter <= 'b0;
      r_out <= in;
    end else begin
      r_counter <= r_counter + 1;
    end

    if (in != r_prev_in) begin
      r_counter <= 'b0;
    end

    r_prev_in <= in;
  end
endmodule
