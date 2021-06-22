
`include "clock.v"

module spi#( parameter SIZE = 40, parameter CLK_DIV = 6 ) (
           input [ SIZE - 1: 0 ] data_in,
           input clk_in,
           input serial_in,
           input send_enable_in,
           output [ SIZE - 1: 0 ] data_out,
           output clk_out,
           output serial_out );

wire r_internal_clk;
reg r_internal_clk_switched;

assign clk_out = r_internal_clk_switched;

// initialize clock divider to spit out approximately 3.2 MHz
divider#( .DIV( CLK_DIV ) ) divider_1 ( .clk_in( clk_in ), .clk_out( r_internal_clk ) );

always @( posedge clk_in ) begin
    if ( send_enable_in )
    begin
        r_internal_clk_switched <= r_internal_clk;
    end
    else
    begin
        r_internal_clk_switched <= 1'b0;
    end
end

piso#( .SIZE( SIZE ) ) piso_1 ( .data_in( data_in ), .clk_in( r_internal_clk_switched ), .r_out( serial_out ) );

sipo#( .SIZE( SIZE ) ) sipo_1 ( .data_in( serial_in ), .clk_in( r_internal_clk_switched ), .r_out( data_out ) );
endmodule
