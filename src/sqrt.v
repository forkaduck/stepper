//https://projectf.io/posts/square-root_out-in-verilog/

// Project F Library - Square Root (Fixed-Point)
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

module sqrt #(
    parameter N = 8,  // width of radicand
    parameter Q = 0   // fractional bits (for fixed point)
) (
    input              clk_in,
    input              start_in,   // start signal
    output reg         busy_out,   // calculation in progress
    output reg         valid_out,  // root_out and rem_out are valid
    input      [N-1:0] rad_in,     // radicand
    output reg [N-1:0] root_out,   // root
    output reg [N-1:0] rem_out     // remainder
);

  reg [N-1:0] x, x_next;  // radicand copy
  reg [N-1:0] q, q_next;  // intermediate root_out (quotient)
  reg [N+1:0] ac, ac_next;  // accumulator (2 bits wider)
  reg [N+1:0] test_res;  // sign test result (2 bits wider)

  localparam ITER = (N + Q) >> 1;  // iterations are half radicand+fbits width
  reg [$clog2(ITER)-1:0] i;  // iteration counter

  always @* begin
    test_res = ac - {q, 2'b01};

    if (test_res[N+1] == 0) begin  // test_res ≥0? (check MSB)
      {ac_next, x_next} = {test_res[N-1:0], x, 2'b0};
      q_next = {q[N-2:0], 1'b1};

    end else begin
      {ac_next, x_next} = {ac[N-1:0], x, 2'b0};
      q_next = q << 1;
    end
  end

  always @(posedge clk_in) begin
    if (start_in) begin
      busy_out <= 1;
      valid_out <= 0;
      i <= 0;
      q <= 0;
      {ac, x} <= {{N{1'b0}}, rad_in, 2'b0};

    end else if (busy_out) begin
      if (i == ITER - 1) begin  // we're done
        busy_out  <= 0;
        valid_out <= 1;
        root_out  <= q_next;
        rem_out   <= ac_next[N+1:2];  // undo final shift

      end else begin  // next iteration
        i  <= i + 1;
        x  <= x_next;
        ac <= ac_next;
        q  <= q_next;
      end
    end
  end
endmodule

