`timescale 1ns / 100ps

`include "macros.v"
`include "../src/clk_divider.v"

module test_clk_divider ();

  reg r_clk;
  reg r_reset;
  parameter integer TP = 1;
  parameter integer CLK_HALF_PERIOD = 5;

  // separate initial process that generates the clk
  initial begin
    r_clk = 0;
    #5;
    forever r_clk = #(CLK_HALF_PERIOD) ~r_clk;
  end

  reg [31:0] i;
  reg r_clk_switched;
  wire clk_output;

  clk_divider #(
      .SIZE(8)
  ) clk_divider1 (
      .clk_in (r_clk_switched),
      .max_in (8'd100),
      .clk_out(clk_output)
  );

  initial begin

    // dump waveform file
    $dumpfile("test_clk_divider.vcd");
    $dumpvars(0, testbench);

    $display("%0t:\tResetting system", $time);

    // pull reset high and wait for 30 clk cycles
    r_reset = #TP 1'b1;
    repeat (30) @(posedge r_clk);

    r_reset = #TP 1'b0;
    repeat (30) @(posedge r_clk);

    $display("%0t:\tBeginning test of the clk_divider module", $time);

    assign r_clk_switched = r_clk;
    for (i = 0; i < 2; i++) begin
      // fix timing offset created by last repeat
      // (works only for i < 2)
      repeat (99 - i) @(posedge r_clk);
      `ASSERT(clk_output, 1'b0);

      repeat (1) @(posedge r_clk);
      `ASSERT(clk_output, 1'b1);

      repeat (1) @(posedge r_clk);
      `ASSERT(clk_output, 1'b0);
    end

    $display("%0t:\tNo errors", $time);
    $finish;
  end

endmodule
