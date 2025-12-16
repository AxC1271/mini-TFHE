`timescale 1ns / 1ps

module comparator (
  input [9:0] val1,  // random number
  input [9:0] val2,  // target value
  output res
);
  // output 1 when random < target
  assign res = (val1 < val2) ? 1'b1 : 1'b0;
endmodule