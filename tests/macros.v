`define ASSERT(signal, value) \
        if (signal !== value) begin \
            $display("%0t:\tASSERTION FAILED in %m | signal != value | 0x%x != 0x%x", $time, signal, value); \
            $finish; \
        end
