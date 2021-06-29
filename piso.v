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
