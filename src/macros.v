`define FIT(bits, num) (bits > $bits(num)) ? {{bits - $bits(num){1'b0}}, num} : num[bits -1: 0]

`define assert_end(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end
