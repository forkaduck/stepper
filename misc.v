module clk_divider#( parameter SIZE = 8 ) (
           input clk_in,
           input [ SIZE - 1: 0 ] max_in,
           output reg clk_out );

reg[ SIZE - 1: 0 ] r_count = 0;

always@( posedge clk_in ) begin
    clk_out <= ( r_count == ( max_in - 1 ) );

    if ( r_count == ( max_in - 1 ) )
    begin
        r_count <= 0;
    end
    else
    begin
        r_count <= r_count + 1;
    end
end
endmodule


    // converts parallel data into serial data
    module piso#( parameter SIZE = 8 ) (
        input [ SIZE - 1: 0 ] data_in,
        input clk_in,
        output reg r_out );

// TODO wrong number of bits shifted out
reg [ SIZE - 1 : 0 ] r_count = SIZE;

always@( posedge clk_in ) begin
    if ( r_count == 0 )
    begin
        r_count <= SIZE;
    end
    else
    begin
        r_count <= r_count - 1;
    end

    r_out <= data_in[ r_count ];
end
endmodule


    // convert serial into parallel data
    module sipo#( parameter SIZE = 8 ) (
        input data_in,
        input clk_in,
        output reg [ SIZE - 1: 0 ] r_out );

always@( posedge clk_in ) begin
    r_out <= { data_in, r_out[ SIZE - 2: 0 ] };
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
