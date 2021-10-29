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
    input  [SIZE - 1:0] data_in,
    output [SIZE - 1:0] data_out,

    // cs selection
    input [$clog2(CS_SIZE) - 1:0] cs_select_in,
    output reg [CS_SIZE - 1 : 0] r_cs_out_n,

    // serial i/o
    input  serial_in,
    output serial_out,

    // output control
    input send_enable_in,
    output reg r_ready_out
);

  reg [$clog2(SIZE) + 1 : 0] r_counter;

  // Internal divided clk
  wire int_clk;

  // send_enable of the previous clk cycle
  reg r_prev_send_enable = 1'b0;

  // Internal clks for sipo and piso
  reg r_int_clk_sipo = 1'b0;
  reg r_int_clk_piso = 1'b0;

  // Intenal enable lines for clk on the above lines
  reg r_int_clk_enable_sipo = 1'b0;
  reg r_int_clk_enable_piso = 1'b0;

  // Load line of the sipo module
  reg r_piso_load = 1'b1;

  assign clk_out = !r_int_clk_sipo;

  initial begin
    r_ready_out = 1'b0;
    r_cs_out_n = ~'b0;
  end

  // initialize clock divider
  clk_divider #(
      .SIZE(CLK_SIZE)
  ) clk_divider1 (
      .clk_in(clk_in),
      .max_in(clk_count_max),
      .r_clk_out(int_clk)
  );

  parameter STATE_IDLE = SIZE + 2;

  // Output always statement
  always @(posedge clk_in) begin
    // state machine output case
    case (r_counter)
      0: begin
        // Pull the current cs down
        r_cs_out_n[cs_select_in] <= 1'b0;
        r_ready_out <= 1'b0;
      end

      // Begin of receiver
      1: r_int_clk_enable_sipo <= 1'b1;

      // Stop loading which happened in the STATE_IDLE state
      2: r_piso_load <= 1'b0;

      // End of data transmission
      SIZE + 1: begin
        r_int_clk_enable_sipo <= 1'b0;
        r_int_clk_enable_piso <= 1'b0;
      end

      default: begin
        if (r_counter >= STATE_IDLE) begin
          // Idle state (wait for send_enable_in)
          r_cs_out_n[cs_select_in] <= 1'b1;
          r_int_clk_enable_sipo <= 1'b0;

          // Load piso
          r_piso_load <= 1'b1;
          r_int_clk_enable_piso <= 1'b1;

          r_ready_out <= 1'b1;
        end
      end
    endcase
  end

  // Next state always statement
  reg r_prev_int_clk;

  always @(posedge clk_in, negedge reset_n_in) begin
    if (!reset_n_in) begin
      r_counter <= STATE_IDLE;

    end else begin
      if (int_clk && !r_prev_int_clk) begin
        case (r_counter)
          STATE_IDLE: begin
            if (send_enable_in && !r_prev_send_enable) begin
              r_counter <= 0;
            end
            r_prev_send_enable <= send_enable_in;
          end

          default: begin
            r_counter <= r_counter + 1;
          end
        endcase
      end

      r_prev_int_clk <= int_clk;
    end
  end

  always @(posedge clk_in) begin
    r_int_clk_sipo <= r_int_clk_enable_sipo ? int_clk : 1'b0;
    r_int_clk_piso <= r_int_clk_enable_piso ? int_clk : 1'b0;
  end

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
