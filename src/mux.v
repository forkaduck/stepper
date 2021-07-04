// multiplexes the current input signal onto one of the selected outputs
module mux#( parameter SIZE = 1 ) (
           input [ SIZE - 1: 0 ] select_in,
           input sig_in,
           input clk_in,
           output reg [ SIZE - 1: 0 ] r_sig_out );

initial
    r_sig_out = 'b0;

always@( posedge clk_in ) begin
    r_sig_out[ select_in ] <= sig_in;
end

endmodule
