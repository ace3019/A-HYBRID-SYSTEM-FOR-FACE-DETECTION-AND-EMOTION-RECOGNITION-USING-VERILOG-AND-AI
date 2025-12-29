# Emotion Classifier Using Verilog

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Verilog](https://img.shields.io/badge/language-Verilog-blue)
![Python](https://img.shields.io/badge/language-Python-yellow)
![Flask](https://img.shields.io/badge/framework-Flask-green)

A hardware-software co-design project that implements a real-time face detector on FPGA hardware (simulated in Verilog) and an emotion classification system using a Python-based Convolutional Neural Network (Mini-Xception).

## Project Overview

This project demonstrates the power of heterogeneous computing by offloading the compute-intensive task of face detection (using the Viola-Jones Haar Cascade algorithm) to dedicated hardware logic, while leveraging the flexibility of software for high-level cognitive tasks like emotion recognition.

### Key Features

*   **Hardware-Accelerated Face Detection:** Efficient Verilog implementation of the Viola-Jones algorithm, designed for FPGA synthesis.
*   **Deep Learning Emotion Recognition:** Python-based Mini-Xception model for classifying emotions (Happy, Sad, Angry, Surprise, Fear, Disgust, Neutral).
*   **Verilog-Python Interface (VPI):** Seamless co-simulation allowing the Verilog testbench to communicate directly with the Python inference server.
*   **Web Interface:** A user-friendly Flask application to upload images, visualize detection results, and see emotion predictions.
*   **Complete Verification Suite:** Includes testbenches, simulation scripts, and visual waveform analysis tools.

## Project Structure

```
├── app.py                  # Flask web application entry point
├── emotion_server.py       # Python server for emotion classification
├── run_project.py          # Helper script to launch the full stack
├── verilog_face_detector/  # (Legacy/Duplicate folder if present)
├── data/                   # ROM initialization files (Cascade & Features)
├── models/                 # Pre-trained Keras models (.h5)
├── sim/                    # Simulation environment (Testbenches, Scripts)
│   ├── prepared_images/    # Hex-converted images for Verilog
│   └── run_sim             # Compiled simulation executable
├── src/                    # Verilog source code
│   ├── face_detector.v     # Top-level module
│   └── ...
├── static/                 # Web assets and uploaded images
├── templates/              # HTML templates for Flask
├── vpi/                    # C-based Verilog Procedural Interface
└── Makefile                # Build automation
```

## Prerequisites

Ensure you have the following installed on your system:

*   **Icarus Verilog:** Open-source Verilog compiler and simulator.
*   **GTKWave:** Waveform viewer for debugging.
*   **Python 3.8+:** Programming language.
*   **GCC:** C compiler for building the VPI interface.

## Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/pratstick/Emotion-Classifier-Using-Verilog.git
    cd Emotion-Classifier-Using-Verilog/verilog_face_detector
    ```

2.  **Set up Virtual Environment**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Install Dependencies**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Prepare Assets**
    Convert the Haar cascade XML and test images into hardware-readable formats:
    ```bash
    make parse-cascade
    make prepare-images
    ```

## Usage

### Automatic Start (Recommended)

We provide a helper script to compile the simulation, start the server, and open the web interface automatically.

```bash
python run_project.py
```

### Manual Simulation

1.  **Compile the Project**
    ```bash
    make compile
    ```

2.  **Start the Emotion Server** (In a separate terminal)
    ```bash
    make start-server
    ```

3.  **Run Co-Simulation**
    ```bash
    make run-cosim
    ```

### Running Tests

To run the full suite of verification tests:

```bash
make test-all
```

## Viewing Waveforms

To analyze the internal signals of the Verilog design:

1.  Run a simulation (e.g., `make run-cosim`).
2.  Open the waveform viewer:
    ```bash
    make wave
    ```

## Technical Details

The system operates in a loop:
1.  **Image Upload:** User uploads an image via the Web UI.
2.  **Preprocessing:** Python converts the image to a grayscale hex map.
3.  **Hardware Detection:** The Verilog simulation reads the hex map and scans for faces using a sliding window and Haar-like features.
4.  **VPI Trigger:** When a face is detected, the Verilog testbench triggers a VPI call.
5.  **Software Classification:** The VPI interface sends the Region of Interest (ROI) to the Python Emotion Server.
6.  **Inference:** The Neural Network predicts the emotion.
7.  **Result:** The prediction is returned to the simulation and displayed on the Web UI.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.