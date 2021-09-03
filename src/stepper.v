
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


  // Tie GPIO0, keep board from rebooting
  assign wifi_gpio0 = 1'b1;
  reg r_slowclock;


  reg [31:0] r_rom[0:1024];
  reg [31:0] r_ram[0:1024];

  initial begin
    // Read the compiled rom into the 2D array
    $readmemh("firmware/target/riscv32imac-unknown-none-elf/release/stepper.txt", r_rom);

    // Read 0's into ram
    $readmemh("/dev/null", r_ram);
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

  // CPU Registers
  reg r_hlt = 'b0;  // halts the cpu

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

  assign led[7:0] = io[7:0];

  darkriscv core1 (
      .CLK(!clk_25mhz),
      .RES(r_state2),
      .HLT(r_hlt),

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



  reg [1:0] r_byte_index;
  // An extremly simplified memory controller
  // TODO byte enable not handled
  //
  // Memory Map (please update constantly):
  // 0x00000000 4KB ROM
  // 0x00000000 4KB RAM
  //
  // 0x10000000 IO

  tenbin converter1 (
      .in (r_byte_e),
      .out(r_byte_index)
  );

  always @(posedge clk_25mhz) begin
    // Instruction read
    r_inst_data <= r_rom[r_inst_addr];

    if (!r_hlt) begin
      // Read cycle
      if (r_read) begin
        // RAM 4KB
        if (r_addr < 32'h00001000) begin
          r_data_in[r_byte_index-:8] <= r_ram[r_addr][r_byte_index-:8];
        end

        if (r_addr == 32'h10000000) begin
          r_data_in[r_byte_index-:8] <= io[r_byte_index-:8];
        end
      end

      // Write cycle
      if (r_write) begin
        if (r_addr < 32'h00001000) begin
          r_ram[r_addr][r_byte_index-:8] <= r_data_out[r_byte_index-:8];
        end

        if (r_addr == 32'h10000000) begin
          io[r_byte_index-:8] <= r_data_out[r_byte_index-:8];
        end
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
