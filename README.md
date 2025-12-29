# A-HYBRID-SYSTEM-FOR-FACE-DETECTION-AND-EMOTION-RECOGNITION-USING-VERILOG-AND-AI
Features a high-performance Verilog implementation of the Viola-Jones algorithm with Integral Image calculation and a sliding window FSM. Supports co-simulation between RTL and a Python deep learning backend for emotion analysis.(VLP 511-Minor Project
)
# Verilog Face and Emotion Classifier

This project implements a Haar Cascade face detector in Verilog and an emotion classifier in Python. The face detector is designed to be synthesized for an FPGA, while the emotion classifier runs on a host machine and communicates with the Verilog simulation.

## Project Structure

```
.
├── verilog_face_detector/
│   ├── create_project.tcl
│   ├── Makefile
│   ├── parse_cascade.py
│   ├── prepare_test_images.py
│   ├── README.md
│   ├── requirements.txt
│   ├── test_cosimulation.sh
│   ├── visualize_architecture.py
│   ├── data/
│   │   ├── cascade_data.coe
│   │   ├── cascade_data.mem
│   │   ├── feature_lut.coe
│   │   ├── feature_lut.mem
│   │   └── haarcascade_frontalface_default.xml
│   ├── models/
│   │   ├── README.md
│   │   └── download_model.py
│   ├── sim/
│   │   ├── image.txt
│   │   ├── run_sim
│   │   ├── tb_face_detector.v
│   │   ├── test_all_images.sh
│   │   ├── waveform.gtkw
│   │   └── prepared_images/
│   │       └── ...
│   ├── src/
│   │   ├── control_fsm.v
│   │   ├── face_detector.v
│   │   ├── face_detector.xdc
│   │   ├── feature_calculator.v
│   │   ├── feature_lut_rom.v
│   │   ├── haar_cascade_rom.v
│   │   ├── integral_image.v
│   │   ├── stage_evaluator.v
│   │   └── weak_classifier.v
│   └── test_images/
│       └── ...
└── venv/
```

## Overview

This project is a hardware/software co-design that combines a hardware-accelerated face detector with a software-based emotion classifier.

*   **Face Detector:** A hardware implementation of the Viola-Jones Haar Cascade algorithm in Verilog. It's designed to be synthesized for a Xilinx FPGA and is capable of real-time face detection in 64x64 grayscale images.
*   **Emotion Classifier:** A Python-based emotion classifier that uses a pre-trained Mini-Xception model. It runs on a host machine and communicates with the Verilog simulation (or the FPGA) to classify the emotions of the detected faces.

## Features

*   **Hardware-Accelerated Face Detection:** The Viola-Jones algorithm is implemented in Verilog for high-performance, real-time face detection.
*   **Software-Based Emotion Classification:** A flexible and powerful emotion classifier that can be easily updated or replaced.
*   **Offline Functionality:** The project is designed to be completely self-contained and work offline. The pre-trained emotion classification model is stored locally.
*   **Vivado Integration:** A Tcl script is provided to automate the creation of a Vivado project for synthesis and deployment on a Xilinx FPGA.
*   **Comprehensive Verification Environment:** The project includes a testbench, simulation scripts, and a co-simulation framework for verifying the functionality of the design.

## Step-by-Step Usage Guide

### 1. Prequisites

*   **Icarus Verilog:** For compiling and running the Verilog simulation.
*   **GTKWave:** For viewing the simulation waveforms.
*   **Python 3:** With the packages listed in `requirements.txt`.
*   **Xilinx Vivado:** For synthesizing and deploying the design on an FPGA.

### 2. Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/Emotion-Classifier-Using-Verilog.git
    cd Emotion-Classifier-Using-Verilog/verilog_face_detector
    ```

2.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **Download the emotion classification model:**
    The emotion classification model is not included in the repository due to its size. You will need to download the pre-trained Mini-Xception model and place it in the `models/` directory.

    *   **Option 1: (Recommended) Implement `download_model.py`**
        The `models/download_model.py` script is a placeholder. You can implement it to automatically download the model from a trusted source.

    *   **Option 2: Manually download the model**
        Download the `emotion_mini_xception.h5` model and place it in the `verilog_face_detector/models/` directory.

4.  **Prepare the Haar Cascade data:**
    The `haarcascade_frontalface_default.xml` file is included in the `data/` directory. Run the following command to convert it to a format that can be used by the Verilog code:
    ```bash
    make parse-cascade
    ```

5.  **Prepare the test images:**
    Place your test images (e.g., `.jpg`, `.png`) in the `test_images/` directory. Then, run the following command to convert them to a format that can be used by the Verilog simulation:
    ```bash
    make prepare-images
    ```

### 3. Simulation

1.  **Start the emotion classification server:**
    In a separate terminal, run the following command to start the Python server that will be used for emotion classification:
    ```bash
    make start-server
    ```

2.  **Run the co-simulation:**
    In another terminal, run the following command to start the Verilog simulation and connect to the emotion classification server:
    ```bash
    make run-cosim
    ```

    You can also run the simulation with a specific image:
    ```bash
    make run-image IMAGE=prepared_images/face_01.txt
    ```

### 4. Verification

The project includes a comprehensive verification environment that allows you to test the functionality of the design.

*   **Testbench:** The `sim/tb_face_detector.v` file is the main testbench for the face detector. It reads a test image, sends it to the `face_detector` module, and checks the output.
*   **Co-simulation:** The co-simulation framework allows you to test the interaction between the Verilog code and the Python-based emotion classifier.
*   **Waveform Debugging:** You can use GTKWave to view the simulation waveforms and debug the design. To open the waveforms, run the simulation and then execute:
    ```bash
    make wave
    ```

    **Key Signals to Monitor in the FSM (`control_fsm.v`):**
    *   `state`: The current state of the finite state machine.
    *   `ii_done`: Indicates that the integral image has been computed.
    *   `stage_start`: Indicates the start of a new stage in the Haar cascade.
    *   `stage_done`: Indicates the end of a stage.
    *   `stage_passed`: Indicates whether the current stage has passed.
    *   `window_x`, `window_y`: The current position of the sliding window.
    *   `done`: Indicates that the face detection process is complete.

### 5. Vivado Deployment

1.  **Generate the Vivado project:**
    Open Vivado and run the following command in the Tcl console:
    ```tcl
    source ../create_project.tcl
    ```
    This will create a new Vivado project, add the Verilog source files, and configure the IP cores.

2.  **Add the constraints file:**
    The `src/face_detector.xdc` file is a template for the design constraints. You will need to modify this file to match the pinout of your target FPGA board.

3.  **Generate the bitstream:**
    In Vivado, click the "Generate Bitstream" button to synthesize the design, implement it, and generate a bitstream.

4.  **Program the FPGA:**
    Use the generated bitstream to program your FPGA.

## Production Readiness

To make this project production-ready, consider the following:

*   **AXI Interface:** For a Zynq-based device, you would need to add an AXI interface to the `face_detector` module to allow the ARM processor to communicate with the FPGA.
*   **Emotion Classification Model:** The Mini-Xception model is a good starting point, but you may want to train your own model for better performance or to recognize a different set of emotions.
*   **Error Handling:** Add more robust error handling to the Python server and the Verilog code.
*   **CI/CD:** Set up a continuous integration and continuous delivery (CI/CD) pipeline to automate the testing and deployment process.

## How It Works

1.  **Haar Cascade:** The face detector uses a Haar cascade to identify faces in an image. The cascade is a series of stages, where each stage is a collection of weak classifiers.
2.  **Integral Image:** An integral image is used to speed up the calculation of the Haar features.
3.  **Sliding Window:** A sliding window is used to scan the image for faces.
4.  **Co-simulation:** The Verilog simulation communicates with the Python-based emotion classifier over a socket connection.
5.  **Vivado Synthesis:** The Verilog code is synthesized for a Xilinx FPGA using Vivado.
--
## Results
<img width="1117" height="561" alt="image" src="https://github.com/user-attachments/assets/479f6c46-b406-4252-b28c-3ddaf1bf477d" />

--
<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/ce4ae7f5-dbbe-4a82-8831-775fcac689b0" />
<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/fe0c1182-35c5-4d2f-8269-e6324c96098d" />


### Contributors
I would like to sincerely thank *Pratyush Kumar* for his valuable collaboration and consistent support throughout this project.The discussions, idea exchanges, and teamwork made this project both productive and enriching.


## References

*   [Viola-Jones object detection framework](https://en.wikipedia.org/wiki/Viola%E2%80%93Jones_object_detection_framework)
*   [OpenCV Haar Cascades](https://github.com/opencv/opencv/tree/master/data/haarcascades)
*   [Mini-Xception: A very deep convolutional neural network for facial expression recognition](https://arxiv.org/abs/1710.07557)
