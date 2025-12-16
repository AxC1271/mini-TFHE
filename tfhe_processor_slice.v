`timescale 1ns / 1ps

// this module increases brightness of a grayscale image
module tfhe_processor_slice (
  input [7:0] byte1, // streamed in image byte
  input [9:0] public_key1, // random number 
  input [7:0] byte2, // represents some constant brightness
  input [9:0] public_key2, // random number
  output[7:0] res
    );

  wire [19:0] ct1, ct2, ct_sum;
  wire [10:0] ct_modulus = 11'd1024; // example ct (q) - 11 bits to hold 1024
  wire [8:0] pt_modulus = 9'd256;    // example pt (p) - 9 bits to hold 256

  // secret key is abstracted away from hep1, hep2, and decryptor modules
  // in the future the public keys will be created using RNGs but input
  // some random number between 0 and q-1 for now
  hep hep1 (
    .pixel_byte(byte1),   
    .public_key(public_key1), // random number
    .ct_modulus(ct_modulus),  
    .pt_modulus(pt_modulus),   
    .error(1'b1), // introduce error to both, e < q/2p or e < 2
    .ciphertext(ct1)
  );

  hep hep2 (
    .pixel_byte(byte2),
    .public_key(public_key2), // random number
    .ct_modulus(ct_modulus),  
    .pt_modulus(pt_modulus),   
    .error(1'b1), // add as much error to increase security and test strength
    .ciphertext(ct2)
  );

  ct_adder ct_addr (
    .ct1(ct1),
    .ct2(ct2),
    .ct_sum(ct_sum)
  );

  hdp decryptor (
    .ciphertext(ct_sum),
    .ct_modulus(ct_modulus),
    .pt_modulus(pt_modulus),
    .res(res)
  );

endmodule