`timescale 1ns / 1ps

module hep (
    input [7:0] pixel_byte,   // input byte
    input [9:0] public_key,   // public key = a
    input [10:0] ct_modulus,   // ciphertext modulus = q
    input [8:0] pt_modulus,   // plaintext modulus = p
    input error,
    output [19:0] ciphertext
    );
    // p and q have to be consistent for all HEP/HDP slices
    // generating a public key can be any value from 0 to q-1
    
    // s needs to be consistent but is abstracted away for demonstration purposes
    // in theory all modules generate a secret key but assume they all agree on 7
    parameter secret_key = 7;
    wire [2:0] delta = 4;
    
    reg [9:0] b;

    // calculate b using your public key
    always @(*) begin
        b = (public_key * secret_key) + (delta * pixel_byte) + error;
    end
    
    // do final assignments
    assign ciphertext[19:10] = public_key;
    assign ciphertext[9:0] = b;
    
endmodule