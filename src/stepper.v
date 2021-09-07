
// top module
// current pinout:
// gp[0] = Step
// gp[1] = Direction
// gp[2] = Driver En
//
// gp[23] = CPU idle
// gp[24] = Debug 0
// gp[25] = Debug 1
// gp[26] = Debug 2
// gp[27] = Debug 3
//
// gn[0] = SDO
// gn[1] = CS
// gn[2] = SCK
// gn[3] = SDI
module stepper (
    input clk_25mhz,
    input [6:0] btn,
    output [7:0] led,
    inout [27:0] gp,
    inout [27:0] gn,
    output wifi_gpio0
);

  wire reset;

  // Tie GPIO0, keep board from rebooting
  assign wifi_gpio0 = 1'b1;

  debounce reset_debounce (
      .clk_in(clk_25mhz),
      .in(btn[1]),
      .out(reset)
  );

  // Memory Map (please update constantly):
  // 0x00000000 4KB ROM
  // 0x00000000 4KB RAM
  //
  // 0x10000000 IO RAM

  // CPU Registers

  wire [31:0] mem_addr;  // memory address
  wire [31:0] mem_wdata;  // cpu write out
  wire [3:0] mem_wstrb;  // byte level write enable
  wire [31:0] mem_rdata;  // cpu read in
  wire [31:0] irq;

  wire mem_valid;  // cpu is ready
  wire mem_instr;  // fetch is instruction
  wire mem_ready;  // memory is ready

  // Instruction ROM
  memory #(
      .DATA_WIDTH(32),
      .DATA_SIZE(1024),
`ifdef __ICARUS__
      .PATH("../firmware/target/riscv32imac-unknown-none-elf/release/stepper.mem")
`else
      .PATH("firmware/target/riscv32imac-unknown-none-elf/release/stepper.mem")
`endif
  ) rom (
      .clk_in(clk_25mhz),
      .enable(mem_instr & mem_valid),
      .write(1'b0),  // constant read (simulate a rom block)
      .ready(mem_ready),
      .addr_in(mem_addr),
      .data_in('b0),
      .r_data_out(mem_rdata)
  );

  // RAM
  memory #(
      .DATA_WIDTH(32),
      .DATA_SIZE(1024),
      .PATH("")
  ) ram (
      .clk_in(clk_25mhz),
      .enable(!mem_instr & mem_valid & !mem_addr[28]),
      .write(mem_wstrb > 0 ? 1'b1 : 1'b0),
      .ready(mem_ready),
      .addr_in(mem_addr),
      .data_in(mem_wdata),  // crossed over because of data_in is the cpu input for data
      .r_data_out(mem_rdata)
  );

  // IO RAM
  io_register #(
      .DATA_WIDTH(32)
  ) io (
      .clk_in(clk_25mhz),
      .enable(!mem_instr & mem_valid & mem_addr[28]),
      .write(mem_wstrb > 0 ? 1'b1 : 1'b0),
      .ready(mem_ready),
      .data_in(mem_wdata),
      .r_data_out(mem_rdata),  // TODO fix multiple driving flipflops

      .r_mem(led[7:0])
  );

  picorv32 #(
      .STACKADDR('d1024),
      .PROGADDR_RESET('b0),
      .PROGADDR_IRQ('b0),
      .ENABLE_MUL('b1),
      .ENABLE_DIV('b1),
      .ENABLE_IRQ(1),
      .ENABLE_IRQ_QREGS('b0)
  ) cpu (
      .clk      (clk_25mhz),
      .resetn   (reset),
      .mem_valid(mem_valid),
      .mem_instr(mem_instr),
      .mem_ready(mem_ready),
      .mem_addr (mem_addr),
      .mem_wdata(mem_wdata),
      .mem_wstrb(mem_wstrb),
      .mem_rdata(mem_rdata),
      .irq      (irq)
  );

  // assign direction pin to fixed 0
  assign gp[1] = 0;
  //
  // motor_driver driver (
  //     .clk_in(clk_25mhz),
  //     .reset_n_in(reset),
  //     .serial_in(gn[0]),
  //     .speed_in('d75),
  //     .step_enable_in(1),
  //     .clk_out(gn[2]),
  //     .serial_out(gn[3]),
  //     .cs_n_out(gn[1]),
  //     .step_out(gp[0])
  // );

endmodule
