`timescale 1ns / 1ps

module ct_adder (
    input [19:0] ct1,
    input [19:0] ct2,
    output [19:0] ct_sum
    );
    
    // adding ciphertexts as shown
    // there's no need to carry since
    // a and b are always bounded by q = 256
    assign ct_sum = {ct1[19:10] + ct2[19:10], ct1[9:0] + ct2[9:0]};
endmodule