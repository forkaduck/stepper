// Maps an external reg as memory into the cpu memory map.
module io_register_input #(
    parameter DATA_WIDTH = 32
) (
    // port
    input  enable_in,
    output ready_out,

    // port
    output [DATA_WIDTH - 1:0] data_out,

    input [DATA_WIDTH - 1:0] mem_in
);
  assign ready_out = enable_in ? 1'b1 : 1'bz;
  assign data_out  = enable_in ? mem_in : {DATA_WIDTH{1'bz}};
endmodule
