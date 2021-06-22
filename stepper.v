
`include "pwm.v"
`include "spi.v"

// top module
module top( input clk_25mhz,
            input [ 6: 0 ] btn,
            output [ 7: 0 ] led,
            inout [ 27: 0 ] gp,
            inout [ 27: 0 ] gn,
            output wifi_gpio0 );


// Tie GPIO0, keep board from rebooting
assign wifi_gpio0 = 1'b1;

wire [ 39: 0 ] out;

spi#( .SIZE( 40 ), .CLK_DIV( 3 ) ) spi_1 ( .data_in( 'b1111000000000000000000000000000000001111 ), .clk_in( clk_25mhz ), .serial_in( gn[ 0 ] ), .send_enable_in( btn[ 1 ] ), .data_out( out ), .clk_out( gn[ 0 ] ), .serial_out( gp[ 0 ] ) );

endmodule
