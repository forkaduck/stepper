// a module dividing the input clock by SIZE
module divider #( parameter DIV = 8 ) ( input clk_in, output clk_out );
reg [ DIV - 1 : 0 ] r_count;

always@( posedge clk_in ) begin
    r_count = r_count + 1;
end

assign clk_out = r_count[ DIV - 1 ];
endmodule

    // converts parallel data into serial data
    module piso#( parameter SIZE = 8 ) ( input [ SIZE - 1: 0 ] in, input clk, output reg r_out );

reg [ SIZE - 1: 0 ] r_count;
reg [ SIZE - 1: 0 ] r_buff;

always@( posedge clk ) begin
    assign r_out = in[ r_count ];
    r_count = r_count + 1;
end
endmodule

    // convert serial into parallel data
    module sipo#( parameter SIZE = 8 ) ( input in, input clk, output reg [ SIZE - 1: 0 ] r_out );

always@( posedge clk ) begin
    r_out = r_out >> 1;
    r_out[ SIZE - 1 ] = in;
end

endmodule
