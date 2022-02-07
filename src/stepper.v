// top module
// current pinout:
// gn[0]      miso
// gn[1]      sck
// gn[2]      mosi
// gn[14:3]   chip select
// gn[26:15]  driver enable lines
// led[7:0]   Debug leds
// gp[11:0]   step lines
// gp[23:12]  dir lines
// gp[27:24]  rc channels
module stepper (
    input clk_25mhz,
    input [6:0] btn,
    output [7:0] led,
    inout [27:0] gp,
    inout [27:0] gn,
    output wifi_gpio0
);

  // Primary clock
  wire cpu_clk;
  wire peripheral_clk;

  // Tie GPIO0, keep board from rebooting
  assign wifi_gpio0 = 1'b1;

  // Debounce all buttons
  wire [6:0] btn_debounced;
  genvar i;
  generate
    for (i = 0; i < 7; i = i + 1) begin
      debounce reset_debounce (
          .clk_in(peripheral_clk),
          .in(!btn[i]),
          .r_out(btn_debounced[i])
      );
    end
  endgenerate

  // Map the button outputs to some functions
  wire reset_n;
  assign reset_n   = btn_debounced[1];

  // step lines
  assign gp[11:1]  = {12{1'b0}};

  // dir lines
  assign gp[23:12] = {12{1'b0}};

  toggle_ff #() peripheral_clk_generator (
      .clk_in(clk_25mhz),
      .toggle_in(1'b1),
      .r_q_out(peripheral_clk)
  );

  toggle_ff #() cpu_clk_generator (
      .clk_in(clk_25mhz),
      .toggle_in(1'b1),
      .r_q_out(cpu_clk)
  );


  // CPU Memory Bus
  wire [31:0] mem_addr;  // memory address
  wire [31:0] mem_wdata;  // cpu write out
  wire [3:0] mem_wstrb;  // byte level write enable (unused)
  wire [31:0] mem_rdata;  // cpu read in
  wire [31:0] irq = 'b0;

  wire mem_valid;  // cpu is ready
  wire mem_instr;  // fetch is instruction
  wire mem_ready;  // memory is ready

  wire trap;

  wire read_write = mem_wstrb == 0 ? 1'b0 : 1'b1;

  // Memory Map (please update constantly):
  //N  Start       Access Name
  //0  0x00000000  r      rom
  //1  0x00001000  rw     ram
  //
  //2  0x10000000  rw     leds
  //3  0x10000004  rw     spi_outgoing_upper
  //4  0x10000008  rw     spi_outgoing_lower
  //5  0x1000000c  r      spi_ingoing_upper
  //6  0x10000010  r      spi_ingoing_lower
  //7  0x10000014  rw     spi_config
  //8  0x10000018  r      spi_status
  //9  0x1000001c  rw     motor_enable
  //10 0x10000020  rw     test_angle_control_upper
  //11 0x10000024  rw     test_angle_control_lower
  //12 0x10000028  r      test_angle_status

  wire [31:0] enable;  // memory enable lines

  assign enable[0] = mem_valid && mem_instr;
  assign enable[1] = mem_valid && !mem_instr && mem_addr >= 'h00001000 && mem_addr < 'h00002000;
  assign enable[2] = mem_valid && !mem_instr && mem_addr >= 'h10000000 && mem_addr < 'h10000004;
  assign enable[3] = mem_valid && !mem_instr && mem_addr >= 'h10000004 && mem_addr < 'h10000008;
  assign enable[4] = mem_valid && !mem_instr && mem_addr >= 'h10000008 && mem_addr < 'h1000000c;
  assign enable[5] = mem_valid && !mem_instr && mem_addr >= 'h1000000c && mem_addr < 'h10000010;
  assign enable[6] = mem_valid && !mem_instr && mem_addr >= 'h10000010 && mem_addr < 'h10000014;
  assign enable[7] = mem_valid && !mem_instr && mem_addr >= 'h10000014 && mem_addr < 'h10000018;
  assign enable[8] = mem_valid && !mem_instr && mem_addr >= 'h10000018 && mem_addr < 'h1000001c;
  assign enable[9] = mem_valid && !mem_instr && mem_addr >= 'h1000001c && mem_addr < 'h10000020;
  assign enable[10] = mem_valid && !mem_instr && mem_addr >= 'h10000020 && mem_addr < 'h10000024;
  assign enable[11] = mem_valid && !mem_instr && mem_addr >= 'h10000024 && mem_addr < 'h10000028;
  assign enable[12] = mem_valid && !mem_instr && mem_addr >= 'h10000028 && mem_addr < 'h1000002c;
  assign enable[31:13] = {32{1'b0}};

  // Instruction RAM
  memory #(
      .DATA_WIDTH(32),
      .DATA_SIZE('h1000),
`ifdef __ICARUS__
      .PATH("../firmware/stepper.mem")
`else
      .PATH("firmware/stepper.mem")
`endif
  ) rom (
      .clk_in(cpu_clk),
      .enable(enable[0]),
      .write(1'b0),  // constant read (simulate a rom block)
      .ready(mem_ready),
      .addr_in(mem_addr[12:0] / 4),
      .data_in('b0),
      .data_out(mem_rdata)
  );

  // RAM
  memory #(
      .DATA_WIDTH(32),
      .DATA_SIZE('h1000),
      .PATH("")
  ) ram (
      .clk_in(cpu_clk),
      .enable(enable[1]),
      .write(read_write),
      .ready(mem_ready),
      .addr_in(mem_addr[12:0] / 4),
      .data_in(mem_wdata),
      .data_out(mem_rdata)
  );

  // LED Register
  io_register_output #(
      .DATA_WIDTH(32)
  ) leds_out (
      .clk_in(cpu_clk),
      .enable(enable[2]),
      .write(read_write),
      .ready(mem_ready),
      .data_in(mem_wdata),
      .data_out(mem_rdata),

      .mem(led[3:0])
  );

  assign led[7] = trap;
  assign led[6] = mem_valid;
  assign led[5] = mem_instr;
  assign led[4] = read_write;

  wire [31:0] spi_outgoing_upper;
  io_register_output #(
      .DATA_WIDTH(32)
  ) spi_reg_out_up (
      .clk_in(cpu_clk),
      .enable(enable[3]),
      .write(read_write),
      .ready(mem_ready),
      .data_in(mem_wdata),
      .data_out(mem_rdata),

      .mem(spi_outgoing_upper)
  );

  wire [31:0] spi_outgoing_lower;
  io_register_output #(
      .DATA_WIDTH(32)
  ) spi_reg_out_low (
      .clk_in(cpu_clk),
      .enable(enable[4]),
      .write(read_write),
      .ready(mem_ready),
      .data_in(mem_wdata),
      .data_out(mem_rdata),

      .mem(spi_outgoing_lower)
  );

  wire [31:0] spi_ingoing_upper;
  io_register_input #(
      .DATA_WIDTH(32)
  ) spi_reg_in_up (
      .enable(enable[5]),
      .ready(mem_ready),
      .data_out(mem_rdata),

      .mem(spi_ingoing_upper)
  );
  assign spi_ingoing_upper[31:8] = 'b0;

  wire [31:0] spi_ingoing_lower;
  io_register_input #(
      .DATA_WIDTH(32)
  ) spi_reg_in_low (
      .enable(enable[6]),
      .ready(mem_ready),
      .data_out(mem_rdata),

      .mem(spi_ingoing_lower)
  );

  // 4:1 - SPI CS Lines / 0 - SPI Send enable
  wire [31:0] spi_config;
  io_register_output #(
      .DATA_WIDTH(32)
  ) spi_reg_config (
      .clk_in(cpu_clk),
      .enable(enable[7]),
      .write(read_write),
      .ready(mem_ready),
      .data_in(mem_wdata),
      .data_out(mem_rdata),

      .mem(spi_config)
  );

  // 0 - SPI ready
  wire [31:0] spi_status;
  io_register_input #(
      .DATA_WIDTH(32)
  ) spi_reg_status (
      .enable(enable[8]),
      .ready(mem_ready),
      .data_out(mem_rdata),

      .mem(spi_status)
  );
  assign spi_status[31:1] = {31{1'b0}};

  spi #(
      .SIZE(40),
      .CS_SIZE(12),
      .CLK_SIZE(3)
  ) spi1 (
      .data_in({spi_outgoing_upper[7:0], spi_outgoing_lower}),
      .clk_in(peripheral_clk),
      .clk_count_max('h4),
      // MISO
      .serial_in(gn[0]),
      .send_enable_in(spi_config[0]),
      .cs_select_in(spi_config[4:1]),
      .reset_n_in(reset_n),
      .data_out({spi_ingoing_upper[7:0], spi_ingoing_lower}),
      // SCK
      .clk_out(gn[1]),
      // MOSI
      .serial_out(gn[2]),
      .r_cs_out_n(gn[14:3]),
      .r_ready_out(spi_status[0])
  );

  // driver enable
  wire [31:0] motor_enable;
  io_register_output #(
      .DATA_WIDTH(32)
  ) motor_reg_enable (
      .clk_in(cpu_clk),
      .enable(enable[9]),
      .write(read_write),
      .ready(mem_ready),
      .data_in(mem_wdata),
      .data_out(mem_rdata),

      .mem(motor_enable)
  );

  assign gn[26:15] = ~motor_enable[11:0];

  wire [31:0] test_angle_control_upper;
  io_register_output #(
      .DATA_WIDTH(32)
  ) test_reg_angle_control_upper (
      .clk_in(cpu_clk),
      .enable(enable[10]),
      .write(read_write),
      .ready(mem_ready),
      .data_in(mem_wdata),
      .data_out(mem_rdata),

      .mem(test_angle_control_upper)
  );

  wire [31:0] test_angle_control_lower;
  io_register_output #(
      .DATA_WIDTH(32)
  ) test_reg_angle_control_lower (
      .clk_in(cpu_clk),
      .enable(enable[11]),
      .write(read_write),
      .ready(mem_ready),
      .data_in(mem_wdata),
      .data_out(mem_rdata),

      .mem(test_angle_control_lower)
  );

  wire [31:0] test_angle_status;
  io_register_input #(
      .DATA_WIDTH(32)
  ) test_reg_angle_status (
      .enable(enable[12]),
      .ready(mem_ready),
      .data_out(mem_rdata),

      .mem(test_angle_status)
  );

  assign test_angle_status[31:1] = {31{1'b0}};

  angle_to_step #(
      .SIZE(64),
      .SCALE({32'd4103, {(64 >> 1) {1'b0}}}),
      .SYSCLK(12000000),
      .VRISE(500),
      .TRISE(500000),
      .OUTPUT_DIV_MIN(100)
  ) test_angle_to_step (
      .clk_i(peripheral_clk),
      .enable_i(test_angle_control_lower[0]),
      .done_o(test_angle_status[0]),
      .relative_angle_i({1'b0, test_angle_control_upper, test_angle_control_lower[31:1]}),
      .step_o(gp[0])
  );

  picorv32 #(
      .ENABLE_COUNTERS(1'b1),
      .ENABLE_COUNTERS64(1'b1),
      .ENABLE_REGS_16_31(1'b1),
      .ENABLE_REGS_DUALPORT(1'b1),
      .LATCHED_MEM_RDATA(1'b0),
      .TWO_STAGE_SHIFT(1'b1),
      .BARREL_SHIFTER(1'b1),
      .TWO_CYCLE_COMPARE(1'b1),
      .TWO_CYCLE_ALU(1'b0),
      .COMPRESSED_ISA(1'b1),
      .CATCH_MISALIGN(1'b1),
      .CATCH_ILLINSN(1'b1),
      .ENABLE_PCPI(1'b0),
      .ENABLE_MUL(1'b0),
      .ENABLE_FAST_MUL(1'b1),
      .ENABLE_DIV(1'b1),
      .ENABLE_IRQ(1'b0),
      .ENABLE_IRQ_QREGS(1'b0),
      .ENABLE_IRQ_TIMER(1'b0),
      .ENABLE_TRACE(1'b0),
      .REGS_INIT_ZERO(1'b1),
      .MASKED_IRQ(32'hffff_ffff),
      .LATCHED_IRQ(32'hffff_ffff),
      .PROGADDR_RESET(32'h00000000),
      .PROGADDR_IRQ(32'h00000000),
      .STACKADDR(32'h00002000)
  ) cpu (
      .clk   (cpu_clk),
      .resetn(reset_n),

      .mem_valid(mem_valid),
      .mem_instr(mem_instr),
      .mem_ready(mem_ready),
      .mem_addr (mem_addr),
      .mem_wdata(mem_wdata),
      .mem_wstrb(mem_wstrb),
      .mem_rdata(mem_rdata),

      .irq(irq),

      .trap(trap)
  );


endmodule
