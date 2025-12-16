`timescale 1ns / 1ps

module image_controller_tb;

    reg clk;
    reg rst_n;
    reg [7:0] brightness;
    
    wire hsync;
    wire vsync;
    wire [3:0] red;
    wire [3:0] green;
    wire [3:0] blue;

    // instantiate the unit under test
    image_controller uut (
        .clk(clk),
        .rst_n(rst_n),
        .brightness(brightness),
        .hsync(hsync),
        .vsync(vsync),
        .red(red),
        .green(green),
        .blue(blue)
    );

    // make 100MHz clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  
    end

    // test variables
    integer i;
    integer non_zero_count;
    integer frame_count;
    
    integer dump_file;
    
    task show_pixel;
        input [11:0] addr;
        begin
            $display("Pixel at address %d:", addr);
            $display("  Original:  0x%02h (%3d)", uut.image_rom[addr], uut.image_rom[addr]);
            $display("  Processed: 0x%02h (%3d)", uut.processed_image[addr], uut.processed_image[addr]);
            $display("  Difference: +0x%02h (+%3d)", 
                     uut.processed_image[addr] - uut.image_rom[addr],
                     uut.processed_image[addr] - uut.image_rom[addr]);
        end
    endtask

    initial begin
        rst_n = 0;
        brightness = 8'h0F;  // add 0x0F to all ROM values
        non_zero_count = 0;
        frame_count = 0;
        
        // create vcd dump for waveform viewing in python
        $dumpfile("image_controller_tb.vcd");
        $dumpvars(0,
            image_controller_tb.uut.hsync,
            image_controller_tb.uut.vsync,
            image_controller_tb.uut.red,
            image_controller_tb.uut.green,
            image_controller_tb.uut.blue,
            image_controller_tb.uut.display_enable
        );

        
        // reset pulse
        #100;
        rst_n = 1;
        #100;
        

        $display("\n========================================");
        $display("Test 1: Verifying ROM Contents");
        $display("========================================");
        
        // wait a bit for initialization
        #1000;
        
        $display("\nAll ROM entries:");
        for (i = 0; i < 4096; i = i + 1) begin
            $display("ROM[%4d] = 0x%02h", i, uut.image_rom[i]);
        end
        
        // count how many non-zero entries exist
        non_zero_count = 0;
        for (i = 0; i < 200; i = i + 1) begin
            if (uut.image_rom[i] != 8'h00) begin
                non_zero_count = non_zero_count + 1;
            end
        end
        
        $display("\nNon-zero ROM entries: %d / 4096", non_zero_count);
        if (non_zero_count == 0) begin
            $display("WARNING: ROM appears to be empty! Check image_data.mem file.");
        end else begin
            $display("ROM loaded successfully with data.");
        end
        
        $display("\n========================================");
        $display("Test 2: Monitoring TFHE Processing");
        $display("========================================");
        $display("Brightness value: 0x%02h (adding 0x0F to each pixel)", brightness);
        
        // monitor state machine
        $display("\nInitial state: %d", uut.state);
        $display("Processing address: %d", uut.process_addr);
        
        // wait for processing to complete
        wait(uut.processing_done == 1'b1);
        $display("\nProcessing completed!");
        $display("Final state: %d", uut.state);
        
        // check some processed pixels
        $display("\nFirst 10 processed pixels (Original + 0x0F):");
        for (i = 0; i < 10; i = i + 1) begin
            $display("Processed[%4d] = 0x%02h (Original: 0x%02h, Expected: 0x%02h)", 
                     i, uut.processed_image[i], uut.image_rom[i], 
                     (uut.image_rom[i] + brightness) & 8'hFF);
        end
        
        $display("\n--- Using show_pixel task ---");
        show_pixel(0);      // first pixel
        $display("CT1  = %020b", uut.tfhe.ct1);
        $display("CT2  = %020b", uut.tfhe.ct2);
        $display("SUM  = %020b", uut.tfhe.ct_sum);
        $display("");
        show_pixel(74);    // random middle pixel
        $display("");
        show_pixel(2047);   // center of image (32, 31)
        $display("");
        show_pixel(4095);   // last pixel
        
        $display("\n========================================");
        $display("Test 3: Monitoring VGA Timing");
        $display("========================================");
        
        // monitor for a few frames
        for (frame_count = 0; frame_count < 3; frame_count = frame_count + 1) begin
            wait(vsync == 0);
            $display("\nFrame %d started", frame_count);
            $display("  h_count: %d, v_count: %d", uut.h_count, uut.v_count);
            
            wait(vsync == 1);
            $display("Frame %d vsync ended", frame_count);
            $display("  h_count: %d, v_count: %d", uut.h_count, uut.v_count);
        end
        
        $display("\n========================================");
        $display("Test 4: Testing Brightness Changes");
        $display("========================================");
        $display("Note: Brightness changes won't affect already processed image");
        $display("      (would need to re-process or reset to see changes)");
        
        brightness = 8'h00;  // minimum
        #10000;
        $display("Brightness = 0x00");
        
        brightness = 8'h20;  // +32
        #10000;
        $display("Brightness = 0x20");
        
        brightness = 8'h0F;  // back to original
        #10000;
        $display("Brightness = 0x0F");
        
        $display("\n========================================");
        $display("Test 5: Sampling Display Output");
        $display("========================================");
        
        // wait for display to be active and sample some pixels
        #1000;
        $display("\nSampling 10 display pixels:");
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            if (uut.display_enable) begin
                $display("Display at h=%d, v=%d: R=%h G=%h B=%h (img_addr=%d)", 
                         uut.h_count, uut.v_count, red, green, blue, uut.img_addr);
            end
        end
        
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("ROM Status: %s", (non_zero_count > 0) ? "LOADED" : "EMPTY");
        $display("Non-zero entries: %d / 4096", non_zero_count);
        $display("Processing: %s", uut.processing_done ? "COMPLETE" : "INCOMPLETE");
        $display("Brightness applied: 0x%02h", brightness);
        $display("Frames monitored: %d", frame_count);
        $display("\nAll tests completed!");
        $display("Check waveform viewer for timing details");
        
        #100000;
        
        $finish;
    end
    
    // timeout watchdog
    initial begin
        #50000000; 
        $display("\nERROR: Testbench timeout!");
        $finish;
    end
    
    always @(posedge clk) begin
        if (uut.state == 1) begin  // PROCESS state
            if (uut.process_addr % 512 == 0) begin  
                $display("Processing progress: %d / 4096", uut.process_addr);
            end
        end
    end

endmodule