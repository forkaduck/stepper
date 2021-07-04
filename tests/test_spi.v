`timescale 1ns/100ps

`include "macros.v"
`include "../src/clk_divider.v"
`include "../src/mux.v"
`include "../src/piso.v"
`include "../src/sipo.v"
`include "../src/spi.v"

module testbench;

reg r_clk;
reg r_reset;
parameter TP = 1;
parameter CLK_HALF_PERIOD = 5;

// separate initial process that generates the clk
initial begin
    r_clk = 0;
    #5;
    forever
        r_clk = #( CLK_HALF_PERIOD ) ~r_clk;
end

reg [ 31: 0 ] i;

reg [ 63: 0 ] r_data_in = 64'hEC000100C30000;
reg r_serial_in = 1'b0;
reg r_send_enable_in = 1'b0;
reg [ 2: 0 ] r_cs_select = 3'b0;
wire [ 63: 0 ] data_out;
wire clk_out;
wire serial_out;
wire [ 2: 0 ] cs_out_n;

spi#( .SIZE( 64 ), .CS_SIZE( 3 ), .CLK_SIZE( 4 ) ) spi1 ( .data_in( r_data_in ), .clk_in( r_clk ), .clk_count_max( 4'd10 ), .serial_in( r_serial_in ), .send_enable_in( r_send_enable_in ), .cs_select_in( r_cs_select ), .reset_n_in(r_reset), .data_out( data_out ), .clk_out( clk_out ), .serial_out( serial_out ), .cs_out_n( cs_out_n ) );

initial begin
    // dump waveform file
    $dumpfile( "test_spi.vcd" );
    $dumpvars( 0, testbench );

    $display( "%0t:\tResetting system", $time );

    // create reset pulse
    r_reset = #TP 1'b1;
    repeat ( 30 ) @ ( posedge r_clk );

    r_reset = #TP 1'b0;
    repeat ( 30 ) @ ( posedge r_clk );

    r_reset = #TP 1'b1;
    repeat ( 30 ) @ ( posedge r_clk );

    $display( "%0t:\tBeginning test of the spi module", $time );

    // test if the chip select goes low during transmission
    `assert( cs_out_n[ 0 ], 1'b1 );
    r_send_enable_in = 1'b1;

    for ( i = 0; i < 64; i += 1 ) begin
        repeat ( 10 ) @( posedge r_clk );
        `assert( cs_out_n[ 0 ], 1'b0 );
        `assert(r_data_in[63 -i], serial_out);
    end

    repeat( 20 ) @( posedge r_clk );
    `assert( cs_out_n[ 0 ], 1'b1 );


    $display( "%0t:\tNo errors", $time );
    $finish;
end

endmodule
