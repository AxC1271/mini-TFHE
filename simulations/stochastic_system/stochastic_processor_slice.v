`timescale 1ns / 1ps

module stochastic_processor_slice (
    input clk,
    input rst_n,
    input start,                   // trigger to begin processing
    input [7:0] byte1,             // streamed in image byte
    input [9:0] public_key1,       // random number 
    input [7:0] byte2,             // represents some constant brightness
    input [9:0] public_key2,       // random number
    output [7:0] res,
    output reg done                // signals completion
);

  wire [19:0] ct1, ct2;
  wire [10:0] ct_modulus = 11'd1024;
  wire [8:0] pt_modulus = 9'd256;

  wire ser_ct1a, ser_ct1b, ser_ct2a, ser_ct2b, sel_a, sel_b, sum_a, sum_b;
  wire [9:0] deser_a, deser_b;
  wire valid_a, valid_b;
  
  // Scale up deserialized values to compensate for MUX averaging
  // MUX gives (a + b) / 2, so multiply by 2 to get actual sum
  wire [10:0] scaled_a = {deser_a, 1'b0};  // Multiply by 2 (left shift)
  wire [10:0] scaled_b = {deser_b, 1'b0};  // Multiply by 2 (left shift)
  
  // Handle overflow - if >= 1024, wrap around (mod 1024)
  wire [9:0] corrected_a = (scaled_a >= 11'd1024) ? (scaled_a - 11'd1024) : scaled_a[9:0];
  wire [9:0] corrected_b = (scaled_b >= 11'd1024) ? (scaled_b - 11'd1024) : scaled_b[9:0];
  
  // Reconstructed ciphertext from deserializers
  wire [19:0] ct_sum;
  assign ct_sum = {corrected_a, corrected_b};  // concatenate upper and lower halves
  
  // control signals
  reg [10:0] bit_counter;
  wire processing;
  wire ready_signal;
  
  // generate ready signal at start of each 1024-bit sequence
  assign ready_signal = (bit_counter == 11'd0);
  assign processing = (bit_counter < 11'd1024);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_counter <= 11'd0;
      done <= 1'b0;
    end else if (start) begin
      bit_counter <= 11'd0;
      done <= 1'b0;
    end else if (processing) begin
      bit_counter <= bit_counter + 1;
      if (bit_counter == 11'd1023)
        done <= 1'b1;
    end
  end

  // encryption modules
  hep hep1 (
      .pixel_byte(byte1),   
      .public_key(public_key1),
      .ct_modulus(ct_modulus),  
      .pt_modulus(pt_modulus),   
      .error(1'b1),
      .ciphertext(ct1)
  );

  hep hep2 (
      .pixel_byte(byte2),
      .public_key(public_key2),
      .ct_modulus(ct_modulus),  
      .pt_modulus(pt_modulus),   
      .error(1'b1),
      .ciphertext(ct2)
  );

  // serializers for ct1 (upper and lower 10 bits)
  // FIXED: Using maximally different seeds (high Hamming distance)
  stochastic_serializer ct1_a (
      .clk(clk),
      .rst_n(rst_n),
      .val(ct1[19:10]),
      .seed(10'b1010101010),  // 0x2AA - alternating pattern
      .ser_output(ser_ct1a)
  );

  stochastic_serializer ct1_b (
      .clk(clk),
      .rst_n(rst_n),
      .val(ct1[9:0]),
      .seed(10'b0101010101),  // 0x155 - inverse alternating
      .ser_output(ser_ct1b)
  );

  // serializers for ct2
  stochastic_serializer ct2_a (
      .clk(clk),
      .rst_n(rst_n),
      .val(ct2[19:10]),
      .seed(10'b1100110011),  // 0x333 - 2-bit pattern
      .ser_output(ser_ct2a)
  );

  stochastic_serializer ct2_b (
      .clk(clk),
      .rst_n(rst_n),
      .val(ct2[9:0]),
      .seed(10'b0011001100),  // 0x0CC - inverse 2-bit pattern
      .ser_output(ser_ct2b)
  );

  // stochastic adders - selection signals
  // FIXED: Using completely different seeds from data serializers
  stochastic_serializer sumsel_a (
      .clk(clk),
      .rst_n(rst_n),
      .val(10'd512),          // middle of distribution (50% probability)
      .seed(10'b1111000011),  // 0x3C3 - different pattern
      .ser_output(sel_a)
  );

  stochastic_serializer sumsel_b (
      .clk(clk),
      .rst_n(rst_n),
      .val(10'd512),          // middle of distribution (50% probability)
      .seed(10'b1000111100),  // 0x23C - another different pattern
      .ser_output(sel_b)
  );

  stochastic_adder adder_a (
      .clk(clk),
      .serial_line1(ser_ct1a),
      .serial_line2(ser_ct2a),
      .sel(sel_a),  
      .sum(sum_a)
  );

  stochastic_adder adder_b (
      .clk(clk),
      .serial_line1(ser_ct1b),
      .serial_line2(ser_ct2b),
      .sel(sel_b),
      .sum(sum_b)
  );

  // deserializers to reconstruct the summed ciphertext
  stochastic_deserializer des1 (
      .clk(clk),
      .ser_input(sum_a),
      .ready(ready_signal),
      .res(deser_a),
      .valid(valid_a)
  );

  stochastic_deserializer des2 (
      .clk(clk),
      .ser_input(sum_b),
      .ready(ready_signal),
      .res(deser_b),
      .valid(valid_b)
  );

  // decryptor - receives the full 20-bit ciphertext ct_sum
  hdp decryptor (
        .ciphertext(ct_sum),
        .ct_modulus(ct_modulus),   // ciphertext modulus = q
        .pt_modulus(pt_modulus),   // plaintext modulus = p
        .res(res)
  );

endmodule