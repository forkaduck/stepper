
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
  reg r_hlt = 0;  // halts the cpu

  wire [31:0] inst_data;  // instruction data bus
  wire [31:0] inst_addr;  // instruction addr bus

  wire [31:0] data_in_byte;
  wire [31:0] data_in;  // data bus
  wire [31:0] data_out;  // data bus
  wire [31:0] data_addr;  // addr bus

  // Access control
  wire [3:0] byte_e;  // byte enable
  wire write;  // write enable
  wire read;  // read enable

  wire read_write = write & ~read;

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
      .enable(1'b1),
      .write(1'b0),  // constant read
      .addr_in(inst_addr[9:0]),
      .data_in('b0),
      .r_data_out(inst_data)
  );

  // RAM
  memory #(
      .DATA_WIDTH(32),
      .DATA_SIZE(1024),
      .PATH("")
  ) ram (
      .clk_in(clk_25mhz),
      .enable(!data_addr[28]),
      .write(read_write),
      .addr_in(data_addr[9:0]),
      .data_in(data_out),  // crossed over because of data_in is the cpu input for data
      .r_data_out(data_in)
  );

  // IO RAM
  io_register #(
      .DATA_WIDTH(32)
  ) io (
      .clk_in(clk_25mhz),
      .enable(data_addr[28]),
      .write(read_write),
      .data_in(data_out),
      .r_data_out(data_in),  // TODO fix multiple driving flipflops

      .r_mem(led[7:0])
  );

  assign data_in_byte = {
    byte_e[3] ? data_in[31:24] : 8'b0,
    byte_e[2] ? data_in[23:16] : 8'b0,
    byte_e[1] ? data_in[15:8] : 8'b0,
    byte_e[0] ? data_in[7:0] : 8'b0
  };

  darkriscv core (
      .CLK(clk_25mhz),
      .RES(!reset),
      .HLT(r_hlt),

      .IDATA(inst_data),
      .IADDR(inst_addr),

      .DATAI(data_in_byte),
      .DATAO(data_out),
      .DADDR(data_addr),

      .BE(byte_e),
      .WR(write),
      .RD(read),

      .IDLE(gp[23]),

      .DEBUG(gp[27:24])
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
