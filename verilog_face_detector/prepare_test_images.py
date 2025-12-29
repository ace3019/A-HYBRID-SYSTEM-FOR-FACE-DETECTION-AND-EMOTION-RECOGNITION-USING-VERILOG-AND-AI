#!/usr/bin/env python3
# prepare_test_images.py
# Converts all images in test_images/ to 64x64 grayscale hex format for Verilog simulation

import os
from pathlib import Path
import numpy as np

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow is not installed. Please run: pip install Pillow numpy")
    exit(1)

INPUT_DIR = Path("test_images")
OUTPUT_DIR = Path("sim/prepared_images")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_WIDTH = 64
OUTPUT_HEIGHT = 64

image_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.pgm']

images = [f for f in INPUT_DIR.iterdir() if f.suffix.lower() in image_extensions]
if not images:
    print(f"No images found in {INPUT_DIR}/. Supported formats: {image_extensions}")
    exit(1)

print(f"Found {len(images)} images in {INPUT_DIR}/. Converting to Verilog hex format...")

for idx, img_path in enumerate(sorted(images), 1):
    try:
        img = Image.open(img_path).convert('L')
        img = img.resize((OUTPUT_WIDTH, OUTPUT_HEIGHT), Image.Resampling.LANCZOS)
        arr = np.array(img)
        out_path = OUTPUT_DIR / f"face_{idx:02d}.txt"
        with open(out_path, 'w') as f:
            for y in range(OUTPUT_HEIGHT):
                for x in range(OUTPUT_WIDTH):
                    f.write(f"{arr[y, x]:02x}\n")
        print(f"[{idx:2d}] {img_path.name:20s} -> {out_path.name}")
    except Exception as e:
        print(f"Error processing {img_path.name}: {e}")

print(f"\nAll images converted. Hex files are in {OUTPUT_DIR}/.")
print("To test, copy one to sim/image.txt and run simulation.")