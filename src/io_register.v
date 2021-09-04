module io_register #(
    parameter DATA_WIDTH = 32,
    parameter DATA_SIZE = 1,
    parameter PATH = ""
) (
    input clk_in,

    // port
    input enable,
    input write,
    input [$clog2(DATA_SIZE) -1:0] addr_in,
    input [DATA_WIDTH - 1:0] data_in,
    output reg [DATA_WIDTH - 1:0] r_data_out,

    // register output
    output reg [DATA_WIDTH - 1:0] r_mem[0:DATA_SIZE - 1]
);

  reg [DATA_WIDTH - 1:0] r_temp;

  initial begin
    if (PATH != "") $readmemh(PATH, r_mem);
  end

  // handle high impedance
  assign r_data_out = enable ? r_temp : 'bz;

  always @(posedge clk_in) begin
    if (enable) begin
      if (write) begin
        r_mem[addr_in] <= data_in;
      end else begin
        r_temp <= r_mem[addr_in];
      end
    end
  end
endmodule
