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

  reg r_curr_cs_n = 1'b1;

  wire int_clk;

  reg r_int_clk_sipo = 1'b0;
  reg r_int_clk_piso = 1'b0;

  reg r_int_clk_enable_sipo = 1'b0;
  reg r_int_clk_enable_piso = 1'b0;

  reg r_piso_load = 1'b0;

  assign clk_out = !r_int_clk_sipo;

  initial r_ready_out = 1'b0;

  // initialize clock divider
  clk_divider #(
      .SIZE(CLK_SIZE)
  ) clk_divider1 (
      .clk_in (clk_in),
      .max_in (clk_count_max),
      .r_clk_out(int_clk)
  );

  parameter STATE_IDLE = 0, STATE_CLK_OFF = SIZE + 2, STATE_END = SIZE + 3;

  always @(posedge clk_in, negedge reset_n_in) begin
    if (!reset_n_in) begin
      r_counter <= STATE_IDLE;
    end else begin
      // state machine output case
      case (r_counter)
        1: begin
          // Pull the current cs down
          r_curr_cs_n <= 1'b0;
        end

        2: begin
          // Begin of receiver
          r_int_clk_enable_sipo <= 1'b1;
        end

        3: begin
          // Stop loading which happened in the STATE_IDLE state
          r_piso_load <= 1'b0;
        end

        // End of data transmission
        STATE_CLK_OFF: begin
          r_int_clk_enable_sipo <= 1'b0;
          r_int_clk_enable_piso <= 1'b0;
        end

        // Disable cs a bit later to avoid a malformed frame
        STATE_END: r_curr_cs_n <= 1'b1;

        default: begin
          if (r_counter == STATE_IDLE || r_counter > STATE_END) begin
            // Idle state (wait for send_enable_in)
            r_curr_cs_n <= 1'b1;
            r_int_clk_enable_sipo <= 1'b0;

            // Load piso
            r_piso_load <= 1'b1;
            r_int_clk_enable_piso <= 1'b1;
          end
        end
      endcase

      if (send_enable_in) begin
        if (r_counter < STATE_END) begin
          // Increment state on positive clk
          if (int_clk) begin
            r_counter <= r_counter + 1;
          end

          r_ready_out <= 1'b0;
        end else begin
          r_ready_out <= 1'b1;
        end
      end else begin
        r_counter <= STATE_IDLE;
        r_ready_out <= 1'b1;
      end
    end
  end

  always @(posedge clk_in) begin
    r_int_clk_sipo <= r_int_clk_enable_sipo ? int_clk : 1'b0;
    r_int_clk_piso <= r_int_clk_enable_piso ? int_clk : 1'b0;
  end

  mux #(
      .SIZE(CS_SIZE),
      .INITIAL(~'b0)
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
      .clk_in  (r_int_clk_piso),
      .load_in (r_piso_load),
      .data_out(serial_out)
  );

  // serial in parallel out module spitting out received data
  sipo #(
      .SIZE(SIZE)
  ) sipo1 (
      .data_in(serial_in),
      .clk_in(r_int_clk_sipo),
      .r_data_out(data_out)
  );
endmodule
