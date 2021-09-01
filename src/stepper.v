
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


  reg [31:0] rom[0:4096];
  reg [31:0] ram[0:4096];

  integer file;
  initial begin
    // Read the compiled rom into the 2D array
    // $readmemb("firmware/target/riscv32imac-unknown-none-elf/release/blink.bin", rom);
    $readmemh("firmware/target/riscv32imac-unknown-none-elf/release/blink.txt", rom);

    // Read 0's into ram
    $readmemb("/dev/null", ram);
  end


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


  // module darkriscv (
  //     input CLK,  // clock
  //     input RES,  // reset
  //     input HLT,  // halt
  //
  //     input  [31:0] IDATA,  // instruction data bus
  //     output [31:0] IADDR,  // instruction addr bus
  //
  //     input  [31:0] DATAI,  // data bus (input)
  //     output [31:0] DATAO,  // data bus (output)
  //     output [31:0] DADDR,  // addr bus
  //
  //
  //     output [3:0] BE,  // byte enable
  //     output       WR,  // write enable
  //     output       RD,  // read enable
  //
  //     output IDLE,  // idle output
  //
  //     output [3:0] DEBUG  // old-school osciloscope based debug! :)
  // );


  // CPU Registers
  reg [31:0] r_inst_data;  // instruction data bus
  reg [31:0] r_inst_addr;  // instruction addr bus

  reg [31:0] r_data_in;  // data bus
  reg [31:0] r_data_out;  // data bus
  reg [31:0] r_addr;  // addr bus

  reg [3:0] r_byte_e;  // byte enable
  reg r_write;  // write enable
  reg r_read;  // read enable

  // IO Registers
  reg [31:0] io;

  assign led[1] = io[0];

  darkriscv core1 (
      .CLK(clk_25mhz),
      .RES(r_state2),
      .HLT(1'b0),

      .IDATA(r_inst_data),
      .IADDR(r_inst_addr),

      .DATAI(r_data_in),
      .DATAO(r_data_out),
      .DADDR(r_addr),

      .BE(r_byte_e),
      .WR(r_write),
      .RD(r_read),

      .IDLE(gp[23]),

      .DEBUG(gp[27:24])
  );

  // An extremly simplified memory controller
  // TODO byte enable not handled
  //
  // Memory Map (please update constantly):
  // 0x00000000 4KB ROM
  // 0x00000000 4KB RAM
  //
  // 0x10000000 IO
  always @(posedge clk_25mhz) begin
    r_inst_data <= rom[r_inst_addr];

    if (r_read) begin
      // RAM 4KB
      if (r_addr < 32'h00001000) begin
        r_data_in <= ram[r_addr];
      end

      if (r_addr == 32'h10000000) begin
        r_data_in <= io;
      end
    end

    if (r_write) begin
      if (r_addr < 32'h00001000) begin
        ram[r_addr] <= r_data_out;
      end

      if (r_addr == 32'h10000000) begin
        io <= r_data_out;
      end
    end
  end


  // assign direction pin to fixed 0
  assign gp[1] = 1'b0;

  motor_driver driver1 (
      .clk_in(clk_25mhz),
      .reset_n_in(r_state2),
      .serial_in(gn[0]),
      .speed_in('d75),
      .step_enable_in(1'b1),
      .clk_out(gn[2]),
      .serial_out(gn[3]),
      .cs_n_out(gn[1]),
      .step_out(gp[0])
  );

endmodule
