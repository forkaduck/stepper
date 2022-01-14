// Register to hold one 32bit value. Can be
// configured to drive some external signals.
module io_register_input #(
    parameter DATA_WIDTH = 32
) (
    // port
    input  enable,
    output ready,

    // port
    output [DATA_WIDTH - 1:0] data_out,

    input [DATA_WIDTH - 1:0] mem
);
  assign ready = enable ? 1'b1 : 1'bz;
  assign data_out = enable ? mem : {DATA_WIDTH{1'bz}};
endmodule
