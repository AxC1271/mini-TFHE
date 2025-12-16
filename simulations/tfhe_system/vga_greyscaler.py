import os
import numpy as np
from PIL import Image

script_dir = os.path.dirname(os.path.abspath(__file__))
image_path = os.path.join(script_dir, "flower_icon.png")

image = Image.open(image_path)
image = image.resize((64, 64))  
image = image.convert('L')  # convert to grayscale

grayscale_array = np.array(image).flatten()

print(f"Total pixels: {len(grayscale_array)}")  # Should be 4096
print(f"Value range: {grayscale_array.min()} to {grayscale_array.max()}")

# Save original grayscale image
image.save('flower_icon_grayscale.png')

# Write to Verilog .mem file (hex format) 
with open("image_data.mem", "w") as f:
    for i, pixel in enumerate(grayscale_array):
        f.write(f"{pixel:02X}")
        if (i + 1) % 64 == 0:  # New line every 64 values (one row)
            f.write("\n")
        else:
            f.write(" ")

print(f"Generated image_data.mem with {len(grayscale_array)} pixels")

with open("image_data.h", "w") as f:
    f.write("#pragma once\n\n")
    f.write("const unsigned char imageData[] = {\n")
    for i, pixel in enumerate(grayscale_array):
        f.write(f"0x{pixel:02X}, ")
        if (i + 1) % 16 == 0:
            f.write("\n")
    f.write("};\n")

print("Generated image_data.h")