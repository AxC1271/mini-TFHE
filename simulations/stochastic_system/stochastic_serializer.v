`timescale 1ns / 1ps

module stochastic_serializer (
  input clk,
  input rst_n,
  input [9:0] val,
  input [9:0] seed,      // seed for LFSR
  output ser_output);

  wire[9:0] random_number;

  lfsr rng (
    .clk(clk),
    .rst_n(rst_n),
    .seed(seed),
    .lfsr_out(random_number)
  );

  comparator comp (
    .val1(random_number),
    .val2(val),
    .res(ser_output)
  );
  
endmodule