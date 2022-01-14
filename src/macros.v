`define FIT(bits, num) (bits > $bits(num)) ? {{bits - $bits(num){1'b0}}, num} : num[bits -1: 0]

`ifdef __ICARUS__
`define ASSERT(value) \
        if ((value) != 'h1) begin \
            $display("%0t:\tASSERTION FAILED in < %m > | < value > != 1'b1 | -> 0x%x", $time, value); \
            $finish; \
        end
`else
`define ASSERT(value) $display("Assertion here");
`endif
