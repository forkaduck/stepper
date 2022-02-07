// At full pulse length (which is 2ms) the module will output
// 50000 at 25MHz
module pwmrx #(
    parameter SIZE   = 32,
    parameter SYSCLK = 25000000
) (
    input clk_in,
    input reset_n_in,

    input pulse_in,
    output reg [SIZE - 1:0] r_width_out
);
  reg [SIZE - 1:0] r_count;
  reg r_prev_pulse = 1'b0;

  always @(posedge clk_in, negedge reset_n_in) begin
    if (!reset_n_in) begin
      r_count <= 1'b0;

    end else begin
      if (pulse_in && !r_prev_pulse) begin
        r_count <= 1'b0;

      end else if (!pulse_in && r_prev_pulse) begin
        r_width_out <= r_count;

      end else begin
        r_count <= r_count + 1;
      end

      r_prev_pulse <= pulse_in;
    end
  end
endmodule
