`timescale 1ns / 1ps

// testbench module for tfhe_processor
module tfhe_processor_slice_tb ();
  // declare internal signals here
  reg[7:0] op1, op2;
  reg[9:0] public_key1, public_key2;
  wire[7:0] res; 
  
  // instantiate unit under test
  tfhe_processor_slice uut (
    .byte1(op1),
    .public_key1(public_key1),
    .byte2(op2),
    .public_key2(public_key2),
    .res(res)
  );
  
  // access internal ciphertext signals for monitoring/comparison
  wire[19:0] ct1 = uut.ct1;
  wire[19:0] ct2 = uut.ct2;
  wire[19:0] ct_sum = uut.ct_sum;
  
  // extract a and b components from ciphertexts
  wire[9:0] ct1_a = ct1[19:10];
  wire[9:0] ct1_b = ct1[9:0];
  wire[9:0] ct2_a = ct2[19:10];
  wire[9:0] ct2_b = ct2[9:0];
  wire[9:0] ct_sum_a = ct_sum[19:10];
  wire[9:0] ct_sum_b = ct_sum[9:0];

  // random number generator
  task apply_random_keys;
    begin
        public_key1 = $random % 1024;
        public_key2 = $random % 1024;
    end
  endtask
  
  // test stimulus
  initial begin
    $display("\n========== TFHE Homomorphic Addition Test ==========");
    $display("Time    op1 op2 | ct1(a,b)      | ct2(a,b)      | ct_sum(a,b)   | res Exp");
    $display("======= === === | ============= | ============= | ============= | === ===");
    
    // test case 1: 0 + 0
    op1 = 8'd0; op2 = 8'd0; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, op1 + op2);
    
    // test case 2: simple additions
    op1 = 8'd5; op2 = 8'd3; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, op1 + op2);
    
    op1 = 8'd10; op2 = 8'd20; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, op1 + op2);
    
    op1 = 8'd50; op2 = 8'd75; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, op1 + op2);
    
    // test case 3: test overflow
    op1 = 8'd255; op2 = 8'd1; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, (op1 + op2) % 256);
    
    op1 = 8'd200; op2 = 8'd100; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, (op1 + op2) % 256);
    
    op1 = 8'd255; op2 = 8'd255; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, (op1 + op2) % 256);
    
    // test case 4: one operand is zero
    op1 = 8'd0; op2 = 8'd123; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, op1 + op2);
    
    op1 = 8'd99; op2 = 8'd0; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, op1 + op2);
    
    // test case 5: power of 2 values
    op1 = 8'd16; op2 = 8'd32; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, op1 + op2);
    
    op1 = 8'd64; op2 = 8'd128; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, op1 + op2);
    
    // test case 6: random values
    op1 = 8'd37; op2 = 8'd89; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, op1 + op2);
    
    op1 = 8'd111; op2 = 8'd222; apply_random_keys();
    #10;
    $display("%7d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d", 
             $time, op1, op2, ct1_a, ct1_b, ct2_a, ct2_b, ct_sum_a, ct_sum_b, res, (op1 + op2) % 256);
    
    // end simulation
    #10;
    $display("\n========== Summary ==========");
    $display("Ciphertext modulus (q): 1024");
    $display("Plaintext modulus (p): 256");
    $display("Ciphertext format: (a, b) where a=public_key, b=computed value");
    $display("Note: ct_sum_a should equal (ct1_a + ct2_a) mod 1024");
    $display("Note: ct_sum_b should equal (ct1_b + ct2_b) mod 1024");
    $display("Testbench completed\n");
    $finish;
  end
endmodule