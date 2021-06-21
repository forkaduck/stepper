
// a module generating a pwm signal on out
module pwm #( parameter SIZE = 8 ) ( input [ SIZE - 1: 0 ] set, input clk, output out );

reg r_out;
reg [ SIZE - 1: 0 ] r_count;

always @( posedge clk ) begin
    if ( r_count >= set )
    begin
        r_out = 1'b0;
    end
    else
    begin
        r_out = 1'b1;
    end

    r_count = r_count + 1'b1;
end

assign out = r_out;
endmodule

    // a module dividing the input clock by SIZE
    module divider #( parameter DIV = 8 ) ( input clk_in, output clk_out );
reg [ DIV - 1 : 0 ] r_count;

always@( posedge clk_in ) begin
    r_count = r_count + 1;
end

assign clk_out = r_count[ DIV - 1 ];
endmodule


    // top module
    module top( input clk_25mhz,
                input [ 6: 0 ] btn,
                output [ 7: 0 ] led,
                inout [ 27: 0 ] gp,
                inout [ 27: 0 ] gn,
                output wifi_gpio0 );


// Tie GPIO0, keep board from rebooting
assign wifi_gpio0 = 1'b1;

pwm#( .SIZE( 8 ) ) inst1 ( .set( 8'b10000000 ), .clk( clk_25mhz ), .out( gp[ 0 ] ) );

endmodule
