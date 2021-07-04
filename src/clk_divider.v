// clock divider
module clk_divider#(parameter SIZE = 8)
                   (input clk_in,
                    input [SIZE - 1: 0] max_in,
                    output reg clk_out);
    
    reg[SIZE - 1: 0] r_count = 0;
    
    always@(posedge clk_in) begin
        clk_out <= (r_count == (max_in - 1));
        
        if (r_count == (max_in - 1)) begin
            r_count <= 0;
        end
        else begin
            r_count <= r_count + 1;
        end
    end
endmodule
    
    
