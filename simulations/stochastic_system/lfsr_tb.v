`timescale 1ns / 1ps

module lfsr_tb();

    reg clk;
    reg rst_n;
    wire[9:0] lfsr_out;

    // generate infinite clock of 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // instantiate design under test
    lfsr uut (
        .clk(clk),
        .seed(10'b1_100_000_000),
        .rst_n(rst_n),
        .lfsr_out(lfsr_out)
    );

initial begin
    // assert rst_n for default behavior
    rst_n = 1'b0; 
    #50;
    rst_n = 1'b1;
end

always @(posedge clk) begin
    $display("Binary: %b, Decimal: %d", lfsr_out, lfsr_out);
end

endmodule