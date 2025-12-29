#!/usr/bin/env python3
import os
import sys
import subprocess
import time
import shutil
from pathlib import Path

def run_test_pipeline(image_path):
    """
    Runs the full Emotion Classification pipeline:
    1. Image -> Hex (prepare)
    2. Start Emotion Server
    3. Run Verilog Simulation (which talks to Server)
    """
    print(f"==================================================")
    print(f"Testing Pipeline with: {image_path}")
    print(f"==================================================")

    # 1. Prepare Image
    print("\n[1] Preparing Image...")
    # We reuse the logic from prepare_test_images.py, but for one file
    try:
        from PIL import Image
        import numpy as np
        
        img = Image.open(image_path).convert('L')
        img = img.resize((64, 64), Image.Resampling.LANCZOS)
        arr = np.array(img)
        
        # Write to sim/image.txt (expected by testbench)
        sim_dir = Path("sim")
        sim_dir.mkdir(exist_ok=True)
        hex_path = sim_dir / "image.txt"
        
        with open(hex_path, 'w') as f:
            for y in range(64):
                for x in range(64):
                    f.write(f"{arr[y, x]:02x}\n")
        print(f"    Converted {image_path} -> {hex_path}")
        
    except Exception as e:
        print(f"ERROR preparing image: {e}")
        return False

    # 2. Compile Simulation (if needed)
    print("\n[2] Compiling Simulation...")
    # We use the Makefile 'compile' target
    try:
        subprocess.run(["make", "compile"], check=True, stdout=subprocess.DEVNULL)
        print("    Compilation successful.")
    except subprocess.CalledProcessError:
        print("ERROR: Compilation failed.")
        return False

    # 3. Start Emotion Server
    print("\n[3] Starting Emotion Server...")
    server_process = subprocess.Popen(
        ["python3", "emotion_server.py", "--port", "8888"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    # Wait a bit for server to start
    time.sleep(1)
    if server_process.poll() is not None:
        print("ERROR: Server failed to start.")
        print(server_process.stderr.read())
        return False
    print("    Server running (PID: {})".format(server_process.pid))

    # 4. Run Co-Simulation
    print("\n[4] Running Verilog Co-Simulation...")
    try:
        # Run the simulation command
        # vvp -M../vpi -mverilog_python_interface run_sim
        # We execute this from the 'sim' directory
        
        cmd = ["vvp", "-M../vpi", "-mverilog_python_interface", "run_sim"]
        
        result = subprocess.run(
            cmd,
            cwd="sim",
            capture_output=True,
            text=True,
            timeout=10 # Timeout in seconds
        )
        
        output = result.stdout
        print("\n--- Simulation Output ---")
        print(output)
        print("-------------------------")
        
        if "FACE DETECTED" in output or "Face detected" in output:
            print("\n✅ SUCCESS: Face detected.")
        else:
            print("\n⚠️  WARNING: No face detected (or string mismatch).")
            
        if "Received Result: Happy" in output or "Received Result: Sad" in output:
             print("✅ SUCCESS: Emotion classified.")
        
    except subprocess.TimeoutExpired:
        print("ERROR: Simulation timed out.")
    except Exception as e:
        print(f"ERROR running simulation: {e}")
    finally:
        # 5. Cleanup
        print("\n[5] Cleanup...")
        server_process.terminate()
        server_process.wait()
        print("    Server stopped.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 test_pipeline.py <image_file>")
        print("Example: python3 test_pipeline.py test_images/000001.jpg")
        sys.exit(1)
        
    img_file = sys.argv[1]
    if not os.path.exists(img_file):
        print(f"File not found: {img_file}")
        sys.exit(1)
        
    run_test_pipeline(img_file)
