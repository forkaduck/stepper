
`include "macros.v"
`include "motor_driver_define.v"

module motor_driver (
    input clk_in,
    input reset_n_in,
    input serial_in,
    input step_enable_in,
    input [63:0] speed_in,
    output clk_out,
    output serial_out,
    output [11:0] cs_n_out,
    output reg step_out
);

  // Seen from the perspective of the motor_driver module
  reg [39:0] r_data_outgoing = 'b0;
  wire [39:0] data_ingoing;
  reg r_send_enable = 1'b0;
  wire ready_spi;

  // Spi clk is approximately 3.2 MHz
  spi #(
      .SIZE(40),
      .CS_SIZE(12),
      .CLK_SIZE(3)
  ) spi1 (
      .data_in(r_data_outgoing),
      .clk_in(clk_in),
      .clk_count_max(3'b111),
      .serial_in(serial_in),
      .send_enable_in(r_send_enable),
      .cs_select_in('b0),
      .reset_n_in(reset_n_in),
      .data_out(data_ingoing),
      .clk_out(clk_out),
      .serial_out(serial_out),
      .cs_out_n(cs_n_out),
      .r_ready_out(ready_spi)
  );

  // All possible states of the setup state machine
  parameter integer Start = 0, ChopConf = 1, IHoldIRun = 2, TPowerDown = 3, EnPwmMode = 4,
      TPwmThrs = 5, PwmConf = 6, End = 7;

  integer r_state = Start;
  reg r_prev_ready_spi = 1'b0;

  // Driver setup state machine
  // This example configuration is directly copied from the datasheet
  always @(posedge clk_in, negedge reset_n_in) begin
    if (!reset_n_in) begin
      r_state <= Start;
      r_send_enable <= 1'b0;
      r_prev_ready_spi <= 1'b0;
    end else begin
      case (r_state)
        ChopConf: begin
          // CHOPCONF: TOFF = 3, HSTRT = 4, HEND = 1, TBL = 2, CHM = 0 (SpreadCycle)
          r_data_outgoing <= 40'hEC000100C3;
          r_send_enable <= 1'b1;
        end

        IHoldIRun: begin
          // IHOLD_IRUN: IHOLD = 10, IRUN = 31 (max. current), IHOLDDELAY = 6
          r_data_outgoing <= 40'h9000061F0A;
          r_send_enable <= 1'b1;
        end

        TPowerDown: begin
          // TPOWERDOWN = 10: Delay before power down in stand still
          r_data_outgoing <= 40'h910000000A;
          r_send_enable <= 1'b1;
        end

        EnPwmMode: begin
          // EN_PWM_MODE = 1 enables StealthChop (with default PWMCONF)
          r_data_outgoing <= 40'h8000000004;
          r_send_enable <= 1'b1;
        end

        TPwmThrs: begin
          // TPWM_THRS = 500 yields a switching velocity about 35000 = ca. 30RPM
          r_data_outgoing <= 40'h93000001F4;
          r_send_enable <= 1'b1;
        end

        PwmConf: begin
          // PWMCONF: AUTO = 1, 2/1024 Fclk, Switch amplitude limit = 200, Grad = 1
          r_data_outgoing <= 40'hF0000401C8;
          r_send_enable <= 1'b1;
        end

        default: begin
          r_data_outgoing <= 40'h0000000000;
          r_send_enable <= 1'b0;
        end
      endcase

      if (r_state < End && ready_spi && !r_prev_ready_spi) begin
        r_send_enable <= 1'b0;
        r_state <= r_state + 1;
      end
      r_prev_ready_spi <= ready_spi;
    end
  end


  wire step_buff;

  // Step pin clock divider
  clk_divider #(
      .SIZE(64)
  ) clk_divider2 (
      .clk_in (clk_in),
      .max_in (speed_in),
      .clk_out(step_buff)
  );

  always @(posedge clk_in) begin
    if (step_enable_in) begin
      step_out <= step_buff;
    end else begin
      step_out <= 1'b0;
    end
  end
endmodule
