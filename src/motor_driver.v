
`include "motor_driver_define.v"

module motor_driver (
    input clk_in,
    input reset_n_in,
    input serial_in,
    input step_enable_in,
    input [63:0] speed_in,
    output clk_out,
    output serial_out,
    output cs_n_out,
    output reg step_out
);

  reg r_curr_cs_n;
  reg [39:0] r_data_outgoing = 'b0;
  wire [39:0] data_ingoing;
  reg r_enable_send = 1'b0;

  assign cs_n_out = r_curr_cs_n;

  // spi motor driver communication instance
  // spi clk is approximately 3.2 MHz
  spi #(
      .SIZE(40),
      .CS_SIZE(1),
      .CLK_SIZE(3)
  ) spi1 (
      .data_in(r_data_outgoing),
      .clk_in(clk_in),
      .clk_count_max(3'b111),
      .serial_in(serial_in),
      .send_enable_in(r_enable_send),
      .cs_select_in(1'b0),
      .reset_n_in(reset_n_in),
      .data_out(data_ingoing),
      .clk_out(clk_out),
      .serial_out(serial_out),
      .cs_out_n(r_curr_cs_n)
  );

  // all possible states of the setup state machine
  parameter reg [3 : 0] ChopConf = 4'h0, Wait0 = 4'h1, IHoldIRun = 4'h2, Wait1 = 4'h3,
      TPowerDown = 4'd4, Wait2 = 4'h5, EnPwmMode = 4'h6, Wait3 = 4'h7, TPwmThrs = 4'h8,
      Wait4 = 4'h9, PwmConf = 4'ha, Wait5 = 4'hb, End = 4'hc;

  reg [3:0] state = ChopConf;

  // driver setup state machine
  always @(posedge clk_in, negedge reset_n_in) begin
    if (!reset_n_in) begin
      state <= ChopConf;
      r_enable_send <= 1'b0;
    end else begin
      if (r_curr_cs_n) begin
        case (state)
          ChopConf: begin
            // CHOPCONF: TOFF = 3, HSTRT = 4, HEND = 1, TBL = 2, CHM = 0 (SpreadCycle)
            r_data_outgoing <= 40'hEC000100C3;
            r_enable_send <= 1'b1;
          end

          Wait0: begin
            r_enable_send <= 1'b0;
          end

          IHoldIRun: begin
            // IHOLD_IRUN: IHOLD = 10, IRUN = 31 (max. current), IHOLDDELAY = 6
            r_data_outgoing <= 40'h9000061F0A;
            r_enable_send <= 1'b1;
          end

          Wait1: begin
            r_enable_send <= 1'b0;
          end

          TPowerDown: begin
            // TPOWERDOWN = 10: Delay before power down in stand still
            r_data_outgoing <= 40'h910000000A;
          end

          EnPwmMode: begin
            // EN_PWM_MODE = 1 enables StealthChop (with default PWMCONF)
            r_data_outgoing <= 40'h8000000004;
          end

          TPwmThrs: begin
            // TPWM_THRS = 500 yields a switching velocity about 35000 = ca. 30RPM
            r_data_outgoing <= 40'h93000001F4;
          end

          PwmConf: begin
            // PWMCONF: AUTO = 1, 2/1024 Fclk, Switch amplitude limit = 200, Grad = 1
            r_data_outgoing <= 40'hF0000401C8;
          end
          default: begin
          end
        endcase

        if (state < End) begin
          state <= state + 1;
        end
      end
    end
  end


  reg r_step_buff;

  // step pin clock divider
  clk_divider #(
      .SIZE(64)
  ) clk_divider2 (
      .clk_in (clk_in),
      .max_in (speed_in),
      .clk_out(r_step_buff)
  );

  always @(posedge clk_in) begin
    if (step_enable_in) begin
      step_out <= r_step_buff;
    end else begin
      step_out <= 1'b0;
    end
  end
endmodule
