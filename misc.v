// a module that divides the input clock by max_in
module clk_divider#( parameter SIZE = 8 ) (
           input clk_in,
           input [ SIZE - 1: 0 ] max_in,
           output reg clk_out );

reg[ SIZE - 1: 0 ] r_count;

always@( posedge clk_in ) begin
    if ( r_count == 0 )
    begin
        clk_out <= 1'b0;
    end

    if ( r_count == max_in )
    begin
        r_count <= 'b0;
        clk_out <= 1'b1;
    end

    r_count <= r_count + 1;
end

endmodule


    // converts parallel data into serial data
    module piso#( parameter SIZE = 8 ) (
        input [ SIZE - 1: 0 ] data_in,
        input clk_in,
        output reg r_out );

// idfk why SIZE and not SIZE -1 (this took like 3 hours to find out and
// I still don't know why this works)
reg [ SIZE - 1 : 0 ] r_count = SIZE;

always@( posedge clk_in ) begin
    if ( r_count == 0 )
    begin
        r_count <= SIZE;
    end
    r_out <= data_in[ r_count ];
    r_count <= r_count - 1;
end
endmodule


    // convert serial into parallel data
    module sipo#( parameter SIZE = 8 ) (
        input data_in,
        input clk_in,
        output reg [ SIZE - 1: 0 ] r_out );

always@( posedge clk_in ) begin
    r_out <= r_out >> 1;
    r_out[ SIZE - 1 ] <= data_in;
end

endmodule


    // multiplexes the current input signal onto one of the selected outputs
    module mux#( parameter SIZE = 1 ) (
        input [ SIZE - 1: 0 ] select_in,
        input sig_in,
        input clk_in,
        output reg [ SIZE - 1: 0 ] r_sig_out );

always@( posedge clk_in ) begin
    r_sig_out[ select_in ] <= sig_in;
end

endmodule

