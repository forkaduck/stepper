// convert serial into parallel data
module sipo#(parameter SIZE = 8)
            (input data_in,
             input clk_in,
             output reg [SIZE - 1: 0] r_data_out);
    
    initial
        r_data_out = 'b0;
    
    always@(posedge clk_in) begin
        r_data_out <= { data_in, r_data_out[SIZE - 2: 0] };
    end
    
endmodule
