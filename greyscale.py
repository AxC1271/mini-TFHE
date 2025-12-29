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

image.save('flower_icon_grayscale.png')

# write to Verilog .mem file (hex format) 
with open("image_data.mem", "w") as f:
    for i, pixel in enumerate(grayscale_array):
        f.write(f"{pixel:02X}")
        if (i + 1) % 64 == 0:  # new line every 64 values (one row)
            f.write("\n")
        else:
            f.write(" ")