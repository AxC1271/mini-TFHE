`timescale 1ns / 1ps

module tb_stochastic_processor_slice();

    reg clk;
    reg rst_n;
    reg start;
    
    reg [7:0] byte1;
    reg [9:0] public_key1;
    reg [7:0] byte2;
    reg [9:0] public_key2;

    wire [7:0] res;
    wire done;
    
    // instantiate unit under test
    stochastic_processor_slice uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .byte1(byte1),
        .public_key1(public_key1),
        .byte2(byte2),
        .public_key2(public_key2),
        .res(res),
        .done(done)
    );
    
    // access internal ciphertext signals for monitoring
    wire [19:0] ct1 = uut.ct1;
    wire [19:0] ct2 = uut.ct2;
    wire [19:0] ct_sum = uut.ct_sum;
    
    // extract a and b components from ciphertexts
    wire [9:0] ct1_a = ct1[19:10];
    wire [9:0] ct1_b = ct1[9:0];
    wire [9:0] ct2_a = ct2[19:10];
    wire [9:0] ct2_b = ct2[9:0];
    wire [9:0] ct_sum_a = ct_sum[19:10];
    wire [9:0] ct_sum_b = ct_sum[9:0];
    
    // also access deserialized values before they become ct_sum
    wire [9:0] deser_a = uut.deser_a;
    wire [9:0] deser_b = uut.deser_b;
    
    // clock generation: 100MHz (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        // initialize inputs
        rst_n = 0;
        start = 0;
        byte1 = 0;
        public_key1 = 0;
        byte2 = 0;
        public_key2 = 0;
        
        $display("\n========== Stochastic TFHE Processor Test ==========");
        $display("Time         op1 op2 | ct1(a,b)      | ct2(a,b)      | deser(a,b)    | ct_sum(a,b)   | res Exp");
        $display("============ === === | ============= | ============= | ============= | ============= | === ===");
        
        // reset sequence
        #20;
        rst_n = 1;
        #20;
        
        // Test cases
        test_addition(8'd0, 8'd0, 10'd123, 10'd456);
        test_addition(8'd5, 8'd3, 10'd234, 10'd567);
        test_addition(8'd10, 8'd20, 10'd345, 10'd678);
        test_addition(8'd50, 8'd75, 10'd456, 10'd789);
        test_addition(8'd255, 8'd1, 10'd567, 10'd890);
        test_addition(8'd200, 8'd100, 10'd678, 10'd123);
        test_addition(8'd255, 8'd255, 10'd789, 10'd234);
        test_addition(8'd0, 8'd123, 10'd890, 10'd345);
        test_addition(8'd99, 8'd0, 10'd123, 10'd456);
        test_addition(8'd16, 8'd32, 10'd234, 10'd567);
        test_addition(8'd64, 8'd128, 10'd345, 10'd678);
        test_addition(8'd37, 8'd89, 10'd456, 10'd789);
        test_addition(8'd111, 8'd222, 10'd567, 10'd890);
        
        $display("\n========== Summary ==========");
        $display("Processing time per operation: 10240 ns (1024 cycles @ 100MHz)");
        $display("Ciphertext modulus (q): 1024");
        $display("Plaintext modulus (p): 256");
        $display("Stochastic stream length: 1024 bits");
        $display("\nExpected ct_sum components:");
        $display("  ct_sum_a ≈ (ct1_a + ct2_a) / 2  [MUX averaging with 50%% sel]");
        $display("  ct_sum_b ≈ (ct1_b + ct2_b) / 2  [MUX averaging with 50%% sel]");
        $display("  deser_a/b: Raw deserialized counts from stochastic streams");
        $display("\nTestbench completed\n");

        #100;
        $finish;
    end
    
    // Task to perform addition test
    task test_addition;
        input [7:0] val1;
        input [7:0] val2;
        input [9:0] pk1;
        input [9:0] pk2;
        reg [8:0] expected;
        integer expected_ct_sum_a, expected_ct_sum_b;
        begin
            expected = val1 + val2;
            
            // Load inputs
            byte1 = val1;
            byte2 = val2;
            public_key1 = pk1;
            public_key2 = pk2;
            
            // Trigger processing
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            
            // Wait a few cycles for ct1/ct2 to stabilize
            repeat(5) @(posedge clk);
            
            // Calculate expected values (MUX gives average)
            expected_ct_sum_a = (ct1_a + ct2_a) / 2;
            expected_ct_sum_b = (ct1_b + ct2_b) / 2;
            
            // Wait for done signal
            @(posedge done);
            
            // Allow a few cycles for output to stabilize
            repeat(5) @(posedge clk);
            
            // Display results in formatted table
            $display("%12d %3d %3d | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | (%3d,%3d)     | %3d %3d %s", 
                     $time, val1, val2, 
                     ct1_a, ct1_b, 
                     ct2_a, ct2_b,
                     deser_a, deser_b,
                     ct_sum_a, ct_sum_b, 
                     res, expected[7:0],
                     (res == expected[7:0]) ? "PASS" : "FAIL");
            
            // Additional debug info for failures
            if (res != expected[7:0]) begin
                $display("             DEBUG: Expected ct_sum ≈ (%0d,%0d), Got (%0d,%0d)", 
                         expected_ct_sum_a, expected_ct_sum_b, ct_sum_a, ct_sum_b);
            end
            
            // Wait before next test
            repeat(10) @(posedge clk);
        end
    endtask
    
    // Timeout watchdog
    initial begin
        #200000000; // 200ms timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule