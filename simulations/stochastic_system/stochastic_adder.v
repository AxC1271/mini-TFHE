`timescale 1ns / 1ps

// at its core a stochastic is just a multiplexer
// muxes are way cheaper than ripple adders, especially
// 20-bit ones as they only take two transmission gates

module stochastic_adder (
  input clk, // needs to be clocked to time properly with bitstream
  input serial_line1,
  input serial_line2,
  input sel, // since we're using a mux with 50% random select
  output reg sum
);

  // simple mux statement
  always @(posedge clk) begin
    sum <= (sel) ? serial_line2 : serial_line1;
  end
  
endmodule