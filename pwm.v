
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
