// a module dividing the input clock by SIZE
module divider #( parameter DIV = 8 ) ( input clk_in, output clk_out );
reg [ DIV - 1 : 0 ] r_count;

always@( posedge clk_in ) begin
    r_count <= r_count + 1;
end

assign clk_out = r_count[ DIV - 1 ];
endmodule

    // generates one pulse if on_in is set to high
    module pulse#( parameter LENGTH = 8 ) ( input clk_in, input on_in, output reg pulse_out );

reg init = 1'b0;
reg [ LENGTH - 1 : 0 ] r_counter;

always@( posedge clk_in ) begin
    if ( on_in && !init )
    begin
        pulse_out <= 1;
        r_counter <= 2 ^ ^ LENGTH;
        init = 1'b1;
    end

    if ( r_counter != 0 )
    begin
        r_counter = r_counter - 1;
    end

    if ( r_counter == 0 )
    begin
        pulse_out <= 0;
        init = 1'b0;
    end
end
endmodule


    // converts parallel data into serial data
    module piso#( parameter SIZE = 8 ) ( input [ SIZE - 1: 0 ] data_in, input clk_in, output reg r_out );

reg [ SIZE - 1: 0 ] r_count;
reg [ SIZE - 1: 0 ] r_buff;

always@( posedge clk_in ) begin
    if ( r_count == SIZE )
    begin
        r_count <= 0;
    end

    r_out <= data_in[ r_count ];
    r_count <= r_count + 1;
end
endmodule


    // convert serial into parallel data
    module sipo#( parameter SIZE = 8 ) ( input data_in, input clk_in, output reg [ SIZE - 1: 0 ] r_out );

always@( posedge clk_in ) begin
    r_out <= r_out >> 1;
    r_out[ SIZE - 1 ] <= data_in;
end

endmodule
