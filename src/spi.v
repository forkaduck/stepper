// A basic spi unit implementing spi mode 3.
module spi #(
    parameter SIZE = 40,
    parameter CS_SIZE = 4,
    parameter CLK_SIZE = 3
) (
    // clk and reset
    input reset_n_in,
    input clk_in,
    output clk_out,
    input [CLK_SIZE - 1:0] clk_count_max,

    // parallel i/o
    input [SIZE - 1:0] data_in,
    output [SIZE - 1:0] data_out,

    // cs selection
    input [$clog2(CS_SIZE) - 1:0] cs_select_in,
    output [CS_SIZE - 1 : 0] cs_out_n,
   
    // serial i/o
    input serial_in,
    output serial_out,

    // output control
    input send_enable_in,
    output reg r_ready_out
);

  reg [$clog2(SIZE) + 1 : 0] r_counter;

  reg r_run = 1'b1;

  reg r_curr_cs_n = 1'b1;

  wire internal_clk;
  reg r_clk_enable_sipo = 1'b0;
  reg r_clk_enable_piso = 1'b0;

  reg r_internal_clk_sipo = 1'b0;
  reg r_internal_clk_piso = 1'b0;

  reg r_piso_load = 1'b0;

  assign clk_out = !r_internal_clk_sipo;

  initial r_ready_out = 1'b0;

  // initialize clock divider
  clk_divider #(
      .SIZE(CLK_SIZE)
  ) clk_divider1 (
      .clk_in (clk_in),
      .max_in (clk_count_max),
      .clk_out(internal_clk)
  );

  parameter integer STATE_CLK_OFF = SIZE + 1, STATE_END = SIZE + 2, STATE_IDLE = SIZE + 3;

  // ready out handling process
  always @(posedge clk_in) begin
    case (r_counter)
      STATE_IDLE: begin
        r_ready_out <= 1'b1;
      end

      default: begin
        r_ready_out <= 1'b0;
      end
    endcase
  end

  always @(posedge internal_clk, negedge reset_n_in) begin
    if (!reset_n_in) begin
      r_counter <= STATE_IDLE;
      r_run <= 1'b1;
    end else begin
      case (r_counter)
        0: begin
          r_curr_cs_n <= 1'b0;
        end

        1: begin
          // begin of load cycle
          r_clk_enable_sipo <= 1'b1;
        end

        2: begin
          r_piso_load <= 1'b0;
        end

        // end of data transmission
        STATE_CLK_OFF: begin
          r_clk_enable_sipo <= 1'b0;
          r_clk_enable_piso <= 1'b0;
        end

        // disable cs a bit later to avoid a malformed frame
        STATE_END: r_curr_cs_n <= 1'b1;

        default: begin
          if (r_counter >= STATE_IDLE) begin
            // Idle state (wait for send_enable_in)
            r_curr_cs_n <= 1'b1;
            r_clk_enable_sipo <= 1'b0;

            // load piso
            r_piso_load <= 1'b1;
            r_clk_enable_piso <= 1'b1;
          end
        end
      endcase

      if (send_enable_in) begin
        // reset counter if enabled and in idle state
        if (r_counter == STATE_IDLE & r_run) begin
          r_counter <= 0;
        end else if (r_counter < STATE_IDLE) begin
          r_counter <= r_counter + 1;
          r_run <= 1'b0;
        end
      end else begin
        // end transmission prematurely
        r_counter <= STATE_IDLE;
        r_run <= 1'b1;
      end
    end
  end

  // fast io handle block
  // handles clock enable signal and ready signal
  always @(posedge clk_in) begin
    // separate the clock enable lines because
    // piso needs one more clk cycle to load
    if (r_clk_enable_sipo) begin
      r_internal_clk_sipo <= internal_clk;
    end else begin
      r_internal_clk_sipo <= 1'b0;
    end

    if (r_clk_enable_piso) begin
      r_internal_clk_piso <= internal_clk;
    end else begin
      r_internal_clk_piso <= 1'b0;
    end
  end

  mux #(
      .SIZE(CS_SIZE),
      .INITIAL(2 ** CS_SIZE - 1)
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
      .data_in (data_in),
      .clk_in  (r_internal_clk_piso),
      .load_in (r_piso_load),
      .data_out(serial_out)
  );

  // serial in parallel out module spitting out received data
  sipo #(
      .SIZE(SIZE)
  ) sipo1 (
      .data_in(serial_in),
      .clk_in(r_internal_clk_sipo),
      .r_data_out(data_out)
  );
endmodule
