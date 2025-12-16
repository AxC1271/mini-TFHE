`timescale 1ns / 1ps

module hdp (
    input [19:0] ciphertext,
    input [10:0] ct_modulus,   // ciphertext modulus = q
    input [8:0] pt_modulus,   // plaintext modulus = p
    output [7:0] res
    );
    
    reg[19:0] res_i;
    
    // p and q have to be consistent for all HEP/HDP slices
    // generating a public key can be any value from 0 to q-1
    
    // s needs to be consistent but is abstracted away for demonstration purposes
    // in theory all modules generate a secret key but assume they all agree on 7
    parameter secret_key = 7;
    reg[1:0] delta_shift = 2; // divide by four means shifting 2 places
    
    // determine the final result
    always @(*) begin
        // first compute b - as mod q
        // b = ciphertext[9:0]
        // a = ciphertext[19:10]
        // s = secret key
        res_i = (ciphertext[9:0] - (ciphertext[19:10] * secret_key)) % ct_modulus;
        res_i = res_i >> delta_shift; // final division to decrypt
    end
    
    assign res = res_i[7:0];
endmodule