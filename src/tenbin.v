module tenbin (
    input [3:0] in,
    output reg [1:0] out
);
  always @(in) begin
    case (in)
      //in     out
      'b0001: out = 'b00;
      'b0010: out = 'b01;
      'b0100: out = 'b10;
      'b1000: out = 'b11;
      default: out = 'b00;
    endcase
  end
endmodule
