
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
  // 0x10000000 IO

  // CPU Registers
  reg r_hlt = 'b0;  // halts the cpu

  wire [31:0] inst_data;  // instruction data bus
  reg [31:0] r_inst_addr;  // instruction addr bus

  reg [31:0] r_data_in;  // data bus
  wire [31:0] data_out;  // data bus
  reg [31:0] r_data_addr;  // addr bus

  // Access control
  reg [3:0] r_byte_e;  // byte enable
  reg r_write;  // write enable
  reg r_read;  // read enable
  wire read_write = r_write & ~r_read;

  // IO Registers
  reg [31:0] io;

  assign led[7:0] = io[7:0];

  // Instruction ROM
  memory #(
      .DATA_WIDTH(32),
      .DATA_SIZE(1024),
      .PATH("firmware/target/riscv32imac-unknown-none-elf/release/stepper.txt")
  ) rom (
      .clk_in(clk_25mhz),
      .read_write(1'b0),  // constant read
      .addr_in(r_inst_addr),
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
      .read_write(read_write),
      .addr_in(r_data_addr),
      .data_in(data_out),  // crossed over because of data_in is the cpu input for data
      .r_data_out(r_data_in)
  );

  darkriscv core (
      .CLK(clk_25mhz),
      .RES(reset),
      .HLT(r_hlt),

      .IDATA(inst_data),
      .IADDR(r_inst_addr),

      .DATAI(r_data_in),
      .DATAO(data_out),
      .DADDR(r_data_addr),

      .BE(r_byte_e),
      .WR(r_write),
      .RD(r_read),

      .IDLE(gp[23]),

      .DEBUG(gp[27:24])
  );

  // assign direction pin to fixed 0
  assign gp[1] = 1'b0;

  motor_driver driver (
      .clk_in(clk_25mhz),
      .reset_n_in(reset),
      .serial_in(gn[0]),
      .speed_in('d75),
      .step_enable_in(1'b1),
      .clk_out(gn[2]),
      .serial_out(gn[3]),
      .cs_n_out(gn[1]),
      .step_out(gp[0])
  );

endmodule
