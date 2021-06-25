
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

reg [ 39: 0 ] data_outgoing;
wire [ 39: 0 ] data_ingoing;
reg enable_send = 1'b0;

//spi clk is approximately 3.2 MHz
spi#( .SIZE( 40 ), .CLK_DIV( 3 ), .CS_SIZE( 1 ), .CLK_SIZE( 3 ) ) spi_1 ( .data_in( data_outgoing ), .clk_in( clk_25mhz ), .clk_count_max( 3'b111 ), .serial_in( gn[ 0 ] ), .send_enable_in( enable_send ), .cs_select( 1'b0 ), .data_out( data_ingoing ), .clk_out( gn[ 2 ] ), .serial_out( gn[ 3 ] ), .r_cs_out( gn[ 1 ] ) );

initial
begin
    data_outgoing = 40'h4206900000;
    enable_send = 1'b1;
end


assign led[ 7: 0 ] = data_ingoing[ 39: 31 ];

endmodule
