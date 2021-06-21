// a module dividing the input clock by SIZE
module divider #( parameter DIV = 8 ) ( input clk_in, output clk_out );
reg [ DIV - 1 : 0 ] r_count;

always@( posedge clk_in ) begin
    r_count = r_count + 1;
end

assign clk_out = r_count[ DIV - 1 ];
endmodule


