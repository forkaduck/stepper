// A memory cell to wrap the inferred type.
// (Makes creating memory a hole lot simpler because of these requirements)
//
// Apparently DP16KD only supports rams with no multiple write ports or asynchronous read ports.
// DP16KD only supports one write and two read ports at the moment but this
// will probably be improved in a few months.
module memory #(
    parameter DATA_WIDTH = 32,
    parameter DATA_SIZE = 1024,
    parameter PATH = ""
) (
    input clk_in,

    // mem port
    input enable,
    input write,
    input [$clog2(DATA_SIZE) -1:0] addr_in,
    input [DATA_WIDTH - 1:0] data_in,
    output reg [DATA_WIDTH - 1:0] r_data_out
);

  reg [DATA_WIDTH - 1:0] r_mem[0:DATA_SIZE - 1];

  integer i;
  initial begin
    if (PATH != "") begin
      $readmemh(PATH, r_mem);
    end else begin
      for (i = 0; i < DATA_SIZE; i++) begin
        r_mem[i] = 'b0;
      end
    end

    r_data_out = 'b0;
  end

  always @(posedge clk_in) begin
    if (enable) begin
      if (write) begin
        r_mem[addr_in] <= data_in;
      end else begin
        r_data_out <= enable ? r_mem[addr_in] : 'bz;
      end
    end
  end
endmodule
