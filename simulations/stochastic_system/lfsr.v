`timescale 1ns / 1ps

module lfsr (
    input wire clk,
    input wire [9:0] seed,
    input wire rst_n,
    output wire [9:0] lfsr_out
);

reg [9:0] lfsr_reg;

// maximal-length LFSR polynomial: x^10 + x^7 + 1
wire feedback_bit;
assign feedback_bit = lfsr_reg[9] ^ lfsr_reg[6];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // use non-zero seed; if seed is 0, use default
        lfsr_reg <= (seed == 10'b0) ? 10'b1 : seed;
    end else begin
        lfsr_reg <= {feedback_bit, lfsr_reg[9:1]};
    end
end

assign lfsr_out = lfsr_reg;

endmodule