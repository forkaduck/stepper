`timescale 1ns/100ps

`include "macros.v"
`include "../src/mux.v"

module testbench;

reg clk;
reg reset;
parameter TP = 1;
parameter CLK_HALF_PERIOD = 5;

// separate initial process that generates the clk
initial
begin
    clk = 0;
    #5;
    forever
        clk = #( CLK_HALF_PERIOD ) ~clk;
end


reg [ 31: 0 ] i;
reg [ 2: 0 ] r_select;
wire [ 2: 0 ] mux_out;
reg r_mux_in;

mux#( .SIZE( 3 ) ) mux1( .select_in( r_select ), .sig_in( r_mux_in ), .clk_in( clk ), .r_sig_out( mux_out ) );

initial
begin

    // dump waveform file
    $dumpfile( "test_mux.vcd" );
    $dumpvars( 0, testbench );

    $display( "%0t:\tReseting system", $time );

    // pull reset high and wait for 30 clk cycles
    reset = #TP 1'b1;
    repeat ( 30 ) @ ( posedge clk );

    reset = #TP 1'b0;
    repeat ( 30 ) @ ( posedge clk );

    $display( "%0t:\tBeginning test of mux", $time );


    for ( i = 0; i < 3; i = i + 1 )
    begin
        repeat ( 1 ) @ ( posedge clk );
        r_select = i;
        r_mux_in = 1'b0;

        repeat ( 1 ) @ ( posedge clk );

        `assert( mux_out[ i ], 1'b0 );

        r_mux_in = 1'b1;
        repeat ( 2 ) @ ( posedge clk );

        `assert( mux_out[ i ], 1'b1 );

    end

    $display( "%0t:\tEnd of mux test", $time );
    $finish;
end

endmodule
