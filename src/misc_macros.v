`define FIT(bits, num) (bits > $bits(num)) ? {{bits - $bits(num){1'b0}}, num} : num[bits -1: 0]
