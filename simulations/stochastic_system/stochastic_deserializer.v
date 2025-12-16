module stochastic_deserializer (
  input clk,
  input ser_input,
  input ready,        // signals start of new bitstream
  output reg [9:0] res,
  output reg valid    // indicates result is ready
);
  reg[9:0] clk_cnt;
  reg[9:0] count;
  reg active;

  always @(posedge clk) begin
    if (ready) begin
      // start new deserialization cycle
      clk_cnt <= 10'd0;
      count <= 10'd0;
      active <= 1'b1;
      valid <= 1'b0;
    end
    else if (active) begin
      if (clk_cnt < 10'd1023) begin
        clk_cnt <= clk_cnt + 1;
        if (ser_input)
          count <= count + 1;
      end
      else begin
        // completed 1024 bits
        res <= count + (ser_input ? 10'd1 : 10'd0);  // capture final bit
        valid <= 1'b1;
        active <= 1'b0;
      end
    end
  end

endmodule