
// top module
module stepper ( input clk_25mhz,
                 input [ 6: 0 ] btn,
                 output [ 7: 0 ] led,
                 inout [ 27: 0 ] gp,
                 inout [ 27: 0 ] gn,
                 output wifi_gpio0 );


// Tie GPIO0, keep board from rebooting
assign wifi_gpio0 = 1'b1;
reg r_slowclock;

tmc2310 #( .SPEED_SIZE( 64 ) ) tmc21301( .clk_in( clk_25mhz ), .reset_n_in( btn[ 1 ] ), .serial_in( gn[ 0 ] ), .speed( 'd25000000 ), .clk_out( gn[ 2 ] ), .serial_out( gn[ 3 ] ), .cs_out_n( gn[ 1 ] ), .step( gp[ 0 ] ) );

// btn debouncer
clk_divider #( .SIZE( 16 ) ) divider1( .clk_in( clk_25mhz ), .max_in( 16'd2500 ), .clk_out( r_slowclock ) );

reg r_state1;
always@( posedge r_slowclock ) begin
    r_state1 <= btn[ 1 ];
    r_slowclock <= r_state1;
end

// assign led[ 7: 0 ] = data_ingoing[ 39: 32 ];
endmodule
