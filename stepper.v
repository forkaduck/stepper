
`include "pwm.v"
`include "clock.v"

// top module
module top( input clk_25mhz,
            input [ 6: 0 ] btn,
            output [ 7: 0 ] led,
            inout [ 27: 0 ] gp,
            inout [ 27: 0 ] gn,
            output wifi_gpio0 );


// Tie GPIO0, keep board from rebooting
assign wifi_gpio0 = 1'b1;

wire div8_clk;

divider#( .DIV( 3 ) ) divider_1 ( .clk_in( clk_25mhz ), .clk_out( div8_clk ) );

pwm#( .SIZE( 8 ) ) pwm_1 ( .set( 8'b10000000 ), .clk( div8_clk ), .out( gp[ 0 ] ) );

endmodule
