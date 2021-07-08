`define ASSERT(signal, value) \
        if (signal !== value) begin \
            $display("%0t:\tASSERTION FAILED in %m at line %0d | signal != value | 0x%x != 0x%x", $time, `__LINE__, signal, value); \
            $finish; \
        end
