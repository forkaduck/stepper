
`include "pwm.v"
`include "misc.v"
`include "spi.v"
`include "tmc2130.v"

// top module
module top ( input clk_25mhz,
             input [ 6: 0 ] btn,
             output [ 7: 0 ] led,
             inout [ 27: 0 ] gp,
             inout [ 27: 0 ] gn,
             output wifi_gpio0 );


// Tie GPIO0, keep board from rebooting
assign wifi_gpio0 = 1'b1;

tmc2310 tmc21301( .clk_in( clk_25mhz ), .reset_n_in( btn[ 1 ] ), .serial_in( gn[ 0 ] ), .clk_out( gn[ 2 ] ), .serial_out( gn[ 3 ] ), .cs_out_n( gn[ 1 ] ) );


// assign led[ 7: 0 ] = data_ingoing[ 39: 32 ];
endmodule
