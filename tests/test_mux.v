`timescale 1ns/100ps

`include "macros.v"
`include "../src/mux.v"

module testbench;

reg r_clk;
reg r_reset;
parameter TP = 1;
parameter CLK_HALF_PERIOD = 5;

// separate initial process that generates the r_clk
initial
begin
    r_clk = 0;
    #5;
    forever
        r_clk = #( CLK_HALF_PERIOD ) ~r_clk;
end


reg [ 31: 0 ] r_i;
reg [ 2: 0 ] r_select;
wire [ 2: 0 ] r_mux_out;
reg r_mux_in;

mux#( .SIZE( 3 ) ) mux1( .select_in( r_select ), .sig_in( r_mux_in ), .clk_in( r_clk ), .r_sig_out( r_mux_out ) );

initial
begin

    // dump waveform file
    $dumpfile( "test_mux.vcd" );
    $dumpvars( 0, testbench );

    $display( "%0t:\tResetting system", $time );

    // pull reset high and wait for 30 r_clk cycles
    r_reset = #TP 1'b1;
    repeat ( 30 ) @ ( posedge r_clk );

    r_reset = #TP 1'b0;
    repeat ( 30 ) @ ( posedge r_clk );

    $display( "%0t:\tBeginning test of the mux module", $time );


    for ( r_i = 0; r_i < 3; r_i = r_i + 1 )
    begin
        repeat ( 1 ) @ ( posedge r_clk );
        r_select = r_i;
        r_mux_in = 1'b0;

        repeat ( 1 ) @ ( posedge r_clk );

        `assert( r_mux_out[ r_i ], 1'b0 );

        r_mux_in = 1'b1;
        repeat ( 2 ) @ ( posedge r_clk );

        `assert( r_mux_out[ r_i ], 1'b1 );

    end

    $display( "%0t:\tEnd", $time );
    $finish;
end

endmodule
