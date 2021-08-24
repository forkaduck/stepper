
// top module
module stepper (
    input clk_25mhz,
    input [6:0] btn,
    output [7:0] led,
    inout [27:0] gp,
    inout [27:0] gn,
    output wifi_gpio0
);


  // Tie GPIO0, keep board from rebooting
  assign wifi_gpio0 = 1'b1;
  reg r_slowclock;

  // btn debouncer
  clk_divider #(
      .SIZE(8)
  ) clk_divider1 (
      .clk_in (clk_25mhz),
      .max_in (8'd250),
      .clk_out(r_slowclock)
  );

  reg r_state1, r_state2;
  always @(posedge r_slowclock) begin
    r_state1 <= ~btn[1];
    r_state2 <= r_state1;
  end

  // assign direction pin to fixed 0
  assign gp[1] = 1'b0;

  motor_driver driver1 (
      .clk_in(clk_25mhz),
      .reset_n_in(r_state2),
      .serial_in(gn[0]),
      .speed_in('d80),
      .step_enable_in(1'b1),
      .clk_out(gn[2]),
      .serial_out(gn[3]),
      .cs_n_out(gn[1]),
      .step_out(gp[0])
  );

  // reg [39: 0] data_outgoing;
  // wire [39: 0] data_ingoing;
  // reg enable_send = 1'b0;
  //
  // // spi clk is approximately 3.2 MHz
  // spi#(.SIZE(40), .CS_SIZE(1), .CLK_SIZE(3)) spi_1 (.data_in(data_outgoing), .clk_in(clk_25mhz), .clk_count_max(3'b111), .serial_in(gn[0]), .send_enable_in(enable_send), .cs_select(1'b0), .data_out(data_ingoing), .clk_out(gn[2]), .serial_out(gn[3]), .r_cs_out_n(gn[1]));
  //
  // initial
  // begin
  // data_outgoing = 40'h4206900000;
  // enable_send = 1'b1;
  // end
endmodule
