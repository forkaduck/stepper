
`include "macros.v"

module spi #(
    parameter integer SIZE = 40,
    parameter integer CS_SIZE = 1,
    parameter integer CLK_SIZE = 3
) (
    input [SIZE - 1:0] data_in,
    input clk_in,
    input [CLK_SIZE - 1:0] clk_count_max,
    input serial_in,
    input send_enable_in,
    input [$clog2(CS_SIZE) - 1:0] cs_select_in,
    input reset_n_in,
    output [SIZE - 1:0] data_out,
    output clk_out,
    output serial_out,
    output [CS_SIZE - 1 : 0] cs_out_n
);

  reg [SIZE - 1 : 0] r_counter = 'b0;

  reg r_curr_cs_n = 1'b1;

  wire internal_clk;
  reg r_clk_enable = 1'b0;
  reg r_internal_clk_switched = 1'b0;

  assign clk_out = r_internal_clk_switched;

  // initialize clock divider
  clk_divider #(
      .SIZE(CLK_SIZE)
  ) clk_divider1 (
      .clk_in (clk_in),
      .max_in (clk_count_max),
      .clk_out(internal_clk)
  );

  parameter integer Idle = 'h0, Start = 'h1, EndClk = SIZE, EndCs = SIZE + 'h1;

  // decide if something should be sent (a sort of monoflop/delay mechanism
  // which sends out the length of the buffer and then waits for another pulse
  // on the enable line)
  always @(posedge internal_clk, negedge reset_n_in) begin
    if (!reset_n_in) begin
      r_counter <= `FIT(SIZE, Idle);
    end else begin
      if (send_enable_in) begin
        if(r_counter < `FIT(SIZE, EndCs)) begin
          r_counter <= r_counter + 1;
        end
      end else begin
        r_counter <= `FIT(SIZE, Idle);
      end

      case (r_counter)
        `FIT(SIZE, Idle): begin
          r_curr_cs_n <= 1'b1;
          r_clk_enable <= 1'b0;
        end

        `FIT(SIZE, Start): begin
          r_curr_cs_n <= 1'b0;
          r_clk_enable <= 1'b1;
        end

        // disable clock to form a frame end
        `FIT(SIZE, EndClk): r_clk_enable <= 1'b0;

        // disable cs a bit later to avoid a malformed frame
        `FIT(SIZE, EndCs): r_curr_cs_n <= 1'b1;

        default: begin
        end
      endcase
    end

    $display("%m>\t\tsend_enable_in:%x r_counter:%x r_curr_cs_n:%x r_clk_enable:%x", send_enable_in,
             r_counter, r_curr_cs_n, r_clk_enable);
  end

  // handle clock enable signal
  always @(posedge clk_in) begin
    if (r_clk_enable) begin
      r_internal_clk_switched <= internal_clk;
    end else begin
      r_internal_clk_switched <= 1'b0;
    end
  end

  mux #(
      .SIZE(CS_SIZE)
  ) mux1 (
      .select_in(cs_select_in),
      .sig_in(r_curr_cs_n),
      .clk_in(clk_in),
      .r_sig_out(cs_out_n)
  );

  // parallel in serial out module driving the mosi pin
  piso #(
      .SIZE(SIZE)
  ) piso1 (
      .data_in(data_in),
      .clk_in(r_internal_clk_switched),
      .reset_n_in(reset_n_in),
      .r_data_out(serial_out)
  );

  // serial in parallel out module spitting out received data
  sipo #(
      .SIZE(SIZE)
  ) sipo1 (
      .data_in(serial_in),
      .clk_in(r_internal_clk_switched),
      .reset_n_in(reset_n_in),
      .r_data_out(data_out)
  );
endmodule
