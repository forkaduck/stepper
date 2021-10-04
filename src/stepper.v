/*
* TODO
* change clkname in clk_divider (missing r_)
* instructions causing a trap:
*   csrwi	mie,0
*   csrwi	mip,0
*   csrr	a2,mhartid
*   csrr	a2,mhartid
*   csrr	a0,mhartid
*   csrw	mtvec,t0
*/

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

  wire reset_n;

  // Tie GPIO0, keep board from rebooting
  assign wifi_gpio0 = 1'b1;
  //
  debounce reset_debounce (
      .clk_in(clk_25mhz),
      .in(!btn[1]),
      .r_out(reset_n)
  );

  // CPU Registers
  wire [31:0] mem_addr;  // memory address
  wire [31:0] mem_wdata;  // cpu write out
  wire [3:0] mem_wstrb;  // byte level write enable
  wire [31:0] mem_rdata;  // cpu read in
  wire [31:0] irq = 'b0;

  wire mem_valid;  // cpu is ready
  wire mem_instr;  // fetch is instruction
  wire mem_ready;  // memory is ready

  wire trap;

  wire read_write = mem_wstrb > 0 ? 1'b1 : 1'b0;

  reg [31:0] enable = 'b0;  // memory enable lines
  // Memory Map (please update constantly):
  // 0x00000000 rom
  // 0x00001000 ram
  //
  // 0x10000000 leds
  always @(posedge clk_25mhz) begin
    if (mem_instr & mem_valid & (mem_addr < 'h00001000)) begin
      enable[0] <= 1'b1;
    end else if (!mem_instr & mem_valid & (mem_addr >= 'h00001000 & mem_addr < 'h00002000)) begin
      enable[1] <= 1'b1;
    end else if (!mem_instr & mem_valid & (mem_addr >= 'h10000000 & mem_addr < 'h10000003)) begin
      enable[2] <= 1'b1;
    end else begin
      enable <= 'b0;
    end
  end

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
      .clk_in(clk_25mhz),
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
      .clk_in(clk_25mhz),
      .enable(enable[1]),
      .write(read_write),
      .ready(mem_ready),
      .addr_in(mem_addr[12:0] / 4),
      .data_in(mem_wdata),  // crossed over because of data_in is the cpu input for data
      .data_out(mem_rdata)
  );

  // IO RAM
  io_register #(
      .DATA_WIDTH(32)
  ) leds (
      .clk_in(clk_25mhz),
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

  picorv32 #(
      .ENABLE_COUNTERS(1'b1),
      .ENABLE_COUNTERS64(1'b1),
      .ENABLE_REGS_16_31(1'b1),
      .ENABLE_REGS_DUALPORT(1'b1),
      .LATCHED_MEM_RDATA(1'b0),
      .TWO_STAGE_SHIFT(1'b0),
      .BARREL_SHIFTER(1'b0),
      .TWO_CYCLE_COMPARE(1'b0),
      .TWO_CYCLE_ALU(1'b0),
      .COMPRESSED_ISA(1'b1),
      .CATCH_MISALIGN(1'b1),
      .CATCH_ILLINSN(1'b1),
      .ENABLE_PCPI(1'b0),
      .ENABLE_MUL(1'b1),
      .ENABLE_FAST_MUL(1'b1),
      .ENABLE_DIV(1'b1),
      .ENABLE_IRQ(1'b0),
      .ENABLE_IRQ_QREGS(1'b1),
      .ENABLE_IRQ_TIMER(1'b0),
      .ENABLE_TRACE(1'b0),
      .REGS_INIT_ZERO(1'b1),
      .MASKED_IRQ(32'hffff_ffff),
      .LATCHED_IRQ(32'hffff_ffff),
      .PROGADDR_RESET(32'h00000000),
      .PROGADDR_IRQ(32'h00000000),
      .STACKADDR(32'h00002000)
  ) cpu (
      .clk   (clk_25mhz),
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

  // assign direction pin to fixed 0
  assign gp[1] = 0;

  // spi #(
  //     .SIZE(40),
  //     .CS_SIZE(12),
  //     .CLK_SIZE(3)
  // ) spi1 (
  //     .data_in({spi_outgoing_upper, spi_outgoing_lower}),
  //     .clk_in(clk_25mhz),
  //     .clk_count_max(3'b111),
  //     .serial_in(gn[0]),
  //     .send_enable_in(spi_send_enable),
  //     .cs_select_in('b0),
  //     .reset_n_in(reset_n),
  //     .data_out({spi_outgoing_upper, spi_outgoing_lower}),
  //     .clk_out(gn[2]),
  //     .serial_out(gn[3]),
  //     .cs_out_n(gn[1]),
  //     .r_ready_out(spi_ready)
  // );
endmodule
