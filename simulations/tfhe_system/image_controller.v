`timescale 1ns / 1ps

module image_controller (
    input clk,              
    input rst_n,
    input [7:0] brightness,
    output hsync,
    output vsync,
    output [3:0] red,
    output [3:0] green,
    output [3:0] blue
);

    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    reg [1:0] clk_div;
    reg pixel_clk;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 0;
            pixel_clk <= 0;
        end else begin
            clk_div <= clk_div + 1;
            if (clk_div == 1) begin
                clk_div <= 0;
                pixel_clk <= ~pixel_clk;
            end
        end
    end

    reg [9:0] h_count, v_count;
    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL-1) begin
                h_count <= 0;
                if (v_count == V_TOTAL-1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    assign hsync = ~((h_count >= H_DISPLAY + H_FRONT) && 
                     (h_count < H_DISPLAY + H_FRONT + H_SYNC));
    assign vsync = ~((v_count >= V_DISPLAY + V_FRONT) &&
                     (v_count < V_DISPLAY + V_FRONT + V_SYNC));

    wire display_enable = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);


    (* ram_style = "block" *) reg [7:0] image_rom [0:4095];
    initial $readmemh("image_data.mem", image_rom);


    (* ram_style = "block" *) reg [7:0] processed_image [0:4095];

    reg [11:0] process_addr;
    reg processing_done;
    reg [2:0] state;

    localparam IDLE    = 3'd0;
    localparam PROCESS = 3'd1;
    localparam DISPLAY = 3'd2;

    wire [9:0] public_key1, public_key2;
    wire [7:0] current_pixel = image_rom[process_addr];
    wire [7:0] processed_pixel;

    lfsr lfsr1 (.clk(clk), .rst_n(rst_n), .seed(10'b1010101010), .lfsr_out(public_key1));
    lfsr lfsr2 (.clk(clk), .rst_n(rst_n), .seed(10'b0101010101), .lfsr_out(public_key2));

    tfhe_processor_slice tfhe (
        .byte1(current_pixel),
        .byte2(brightness),
        .public_key1(public_key1),
        .public_key2(public_key2),
        .res(processed_pixel)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            process_addr <= 0;
            processing_done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    process_addr <= 0;
                    processing_done <= 0;
                    state <= PROCESS;
                end
                PROCESS: begin
                    processed_image[process_addr] <= processed_pixel;
                    if (process_addr == 4095) begin
                        state <= DISPLAY;
                        processing_done <= 1;
                    end else begin
                        process_addr <= process_addr + 1;
                    end
                end
                DISPLAY: state <= DISPLAY;
            endcase
        end
    end

    wire in_image_area = (h_count < 512) && (v_count < 480);  
    
    wire [5:0] img_x = h_count[8:3]; 
    wire [5:0] img_y = v_count[8:3];  
    
    wire [11:0] img_addr = (img_y * 64) + img_x;

    wire [7:0] display_pixel = image_rom[img_addr];
    
    wire [3:0] gray_value = display_pixel[7:4];

    // final rgb assignments
    assign red   = (display_enable && in_image_area) ? gray_value : 4'h0;
    assign green = (display_enable && in_image_area) ? gray_value : 4'h0;
    assign blue  = (display_enable && in_image_area) ? gray_value : 4'h0;

endmodule