#!/usr/bin/env python3
"""
VGA VCD to Image Converter
Reads VCD file from Verilog simulation and generates PNG images of VGA output
"""

from vcdvcd import VCDVCD
from PIL import Image
import numpy as np
import sys

def vcd_to_image(vcd_file, output_prefix='frame'):
    """
    Convert VCD file containing VGA signals to PNG images
    
    Args:
        vcd_file: Path to VCD file from simulation
        output_prefix: Prefix for output image files
    """
    
    print(f"Loading VCD file: {vcd_file}")
    vcd = VCDVCD(vcd_file)
    
    try:
        hsync = vcd['image_controller_tb.uut.hsync']
        vsync = vcd['image_controller_tb.uut.vsync']
        red = vcd['image_controller_tb.uut.red[3:0]']
        green = vcd['image_controller_tb.uut.green[3:0]']
        blue = vcd['image_controller_tb.uut.blue[3:0]']
        display_en = vcd['image_controller_tb.uut.display_enable']
    except KeyError as e:
        print(f"Error: Could not find signal {e}")
        print("Available signals:")
        for sig in vcd.signals:
            print(f"  {sig}")
        return
    
    H_DISPLAY = 640
    V_DISPLAY = 480
    
    frame_buffer = np.zeros((V_DISPLAY, H_DISPLAY, 3), dtype=np.uint8)
    
    def get_value_at(tv_list, time, last_value=0):
        """
        Returns the value of a VCD signal at a given time.
        tv_list: list of (time, value) tuples from VCDVCD
        """
        value = last_value
        for t, v in tv_list:
            if t > time:
                break
            value = v
        return value
    
    x = 0
    y = 0
    frame_count = 0
    in_display_area = False
    last_hsync = 1
    last_vsync = 1
    
    times = sorted(set(hsync.tv) | set(vsync.tv) | set(red.tv) | 
                   set(green.tv) | set(blue.tv) | set(display_en.tv))
    
    for i, time in enumerate(times):
        h = int(get_value_at(hsync.tv, time, last_hsync))
        v = int(get_value_at(vsync.tv, time, last_vsync))
        r = int(get_value_at(red.tv, time, 0))
        g = int(get_value_at(green.tv, time, 0))
        b = int(get_value_at(blue.tv, time, 0))
        de = int(get_value_at(display_en.tv, time, 0))

        
        # convert 4-bit to 8-bit color
        r_val = int(r) * 17 if r != 'x' else 0 
        g_val = int(g) * 17 if g != 'x' else 0
        b_val = int(b) * 17 if b != 'x' else 0
        
        # detect hsync falling edge (start of hsync pulse)
        if last_hsync == 1 and h == 0:
            x = 0
            in_display_area = (y < V_DISPLAY)
        
        if last_vsync == 1 and v == 0:
            if frame_count > 0 and np.any(frame_buffer > 0):
                img = Image.fromarray(frame_buffer)
                filename = f"{output_prefix}_{frame_count:03d}.png"
                img.save(filename)
                print(f"Saved frame {frame_count}: {filename}")
            
            y = 0
            x = 0
            frame_count += 1
            frame_buffer = np.zeros((V_DISPLAY, H_DISPLAY, 3), dtype=np.uint8)
            in_display_area = True
        
        if de == 1 and in_display_area and x < H_DISPLAY and y < V_DISPLAY:
            frame_buffer[y, x] = [r_val, g_val, b_val]
            x += 1
            
            if x >= H_DISPLAY:
                x = 0
                y += 1
                in_display_area = (y < V_DISPLAY)
        
        last_hsync = h
        last_vsync = v
        
        if i % 100000 == 0:
            print(f"  Processed {i}/{len(times)} time points, frame {frame_count}, y={y}")
    
    if np.any(frame_buffer > 0):
        img = Image.fromarray(frame_buffer)
        filename = f"{output_prefix}_{frame_count:03d}.png"
        img.save(filename)
        print(f"Saved final frame {frame_count}: {filename}")
    
    print(f"\nTotal frames captured: {frame_count}")
    print(f"Output files: {output_prefix}_001.png to {output_prefix}_{frame_count:03d}.png")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python vga_vcd_to_image.py <vcd_file> [output_prefix]")
        print("Example: python vga_vcd_to_image.py image_controller_tb.vcd frame")
        sys.exit(1)
    
    vcd_file = sys.argv[1]
    output_prefix = sys.argv[2] if len(sys.argv) > 2 else "frame"
    
    vcd_to_image(vcd_file, output_prefix)