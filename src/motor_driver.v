
`include "macros.v"

// General interfacing
`define WRITE_ADDR 8'h80

// General Configuration Registers
`define GCONF 8'h00
`define GSTAT 8'h01
`define IOIN 8'h04

// Velocity Dependent Driver Feature Control Register Set
`define IHOLD_IRUN 8'h10
`define TPOWERDOWN 8'h11
`define TSTEP 8'h12
`define TPWMTHRS 8'h13
`define TCOOLTHRS 8'h14
`define THIGH 8'h15

// SPI Mode Register
`define XDIRECT 8'h2d

// DcStep Minimum Velocity Register
`define VDCMIN 8'h33

// Motor Driver Register
`define MSLUT0 8'h60
`define MSLUT1 8'h61
`define MSLUT2 8'h62
`define MSLUT3 8'h63
`define MSLUT4 8'h64
`define MSLUT5 8'h65
`define MSLUT6 8'h66
`define MSLUT7 8'h67
`define MSLUTSEL 8'h68
`define MSLUTSTART 8'h69
`define MSCNT 8'h6a
`define MSCURACT 8'h6b
`define CHOPCONF 8'h6c
`define COOLCONF 8'h6d
`define DCCTRL 8'h6e
`define DRV_STATUS 8'h6f
`define PWMCONF 8'h70
`define PWM_SCALE 8'h71
`define ENCM_CTRL 8'h72
`define LOST_STEPS 8'h73


module motor_driver (
    input clk_in,
    input reset_n_in,
    input serial_in,
    input step_enable_in,
    input [63:0] speed_in,
    output clk_out,
    output serial_out,
    output [11:0] cs_n_out,
    output step_out
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
  parameter integer Start = 0, End = 10;

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
      // set off_time = 8 and blank_time = 1
      case (r_state)
        1: begin
          r_data_outgoing <= {`GSTAT, 32'h00000000};
          r_send_enable <= 1'b1;
        end

        2: begin
          r_data_outgoing <= {`GSTAT, 32'h00000000};
          r_send_enable <= 1'b1;
        end

        3: begin
          // GCONF
          r_data_outgoing <= {`GCONF + `WRITE_ADDR, 32'h00000022};
          r_send_enable <= 1'b1;
        end

        4: begin
          // CHOPCONF
          // r_data_outgoing <= {`CHOPCONF + `WRITE_ADDR, 32'h200c8188};
          r_data_outgoing <= {`CHOPCONF + `WRITE_ADDR, 32'h30088188};
          r_send_enable <= 1'b1;
        end

        5: begin
          // IHOLD_IRUN IHOLDDELAY / IRUN / IHOLD
          r_data_outgoing <= {`IHOLD_IRUN + `WRITE_ADDR, 32'h00081f1f};
          r_send_enable <= 1'b1;
        end

        6: begin
          // TPOWERDOWN
          r_data_outgoing <= {`TPOWERDOWN + `WRITE_ADDR, 32'h0000000a};
          r_send_enable <= 1'b1;
        end

        7: begin
          // TPWM_THRS
          r_data_outgoing <= {`TPWMTHRS + `WRITE_ADDR, 32'h000001f4};
          r_send_enable <= 1'b1;
        end

        8: begin
          // PWMCONF
          r_data_outgoing <= {`PWMCONF + `WRITE_ADDR, 32'h000401c8};
          r_send_enable <= 1'b1;
        end

        9: begin
          // THIGH
          r_data_outgoing <= {`THIGH + `WRITE_ADDR, 32'h00000032};
          r_send_enable <= 1'b1;
        end

        default: begin
          r_data_outgoing <= {`TSTEP, 32'h00000000};
          r_send_enable <= 1'b1;

          // r_data_outgoing <= 40'h0000000000;
          // r_send_enable <= 1'b0;
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

  // divide frequency by 2 to get a nice 50% square wave
  toggle_ff toggle_ff1 (
      .clk_in(step_buff),
      .toggle_in(step_enable_in),
      .q_out(step_out)
  );

endmodule
