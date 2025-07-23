// Code your design here
module mul(
  input [2:0] a,
  input [2:0] b,
  input clk,
  output reg [5:0] out
);
  always @(posedge clk) begin
  	out <= a*b;
  end
endmodule