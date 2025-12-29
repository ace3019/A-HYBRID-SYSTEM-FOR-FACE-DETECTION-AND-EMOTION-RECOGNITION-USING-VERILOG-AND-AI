# Makefile for Emotion Classification Co-Simulation
# Builds VPI module and runs Verilog-Python co-simulation

# Compiler and flags
CC = gcc
CFLAGS = -fPIC -Wall -I$(shell iverilog-vpi --cflags)
LDFLAGS = -shared
VPI_CFLAGS = $(shell iverilog-vpi --cflags)
VPI_LDFLAGS = $(shell iverilog-vpi --ldflags)

# Directories
VPI_DIR = vpi
SRC_DIR = src
SIM_DIR = sim
DATA_DIR = data

# Files
VPI_SRC = $(VPI_DIR)/verilog_python_interface.c
VPI_OBJ = $(VPI_DIR)/verilog_python_interface.o
VPI_LIB = $(VPI_DIR)/verilog_python_interface.vpi

VERILOG_SRCS = $(wildcard $(SRC_DIR)/*.v)
TB_EMOTION = $(SIM_DIR)/tb_emotion_classifier.v
TB_FACE = $(SIM_DIR)/tb_face_detector.v

SIM_EXEC = $(SIM_DIR)/run_sim
IMAGE_FILE = $(SIM_DIR)/image.txt

# Python server
PYTHON = ./venv/bin/python
EMOTION_SERVER = emotion_server.py
MODELS_DIR = models
EMOTION_MODEL = $(MODELS_DIR)/emotion_mini_xception.h5

# Default target
.PHONY: all
all: vpi help

# Build VPI module
.PHONY: vpi
vpi: $(VPI_LIB)

$(VPI_OBJ): $(VPI_SRC)
	@mkdir -p $(VPI_DIR)
	@echo "Compiling VPI module..."
	iverilog-vpi --name=$(VPI_DIR)/verilog_python_interface $(VPI_SRC)

$(VPI_LIB): $(VPI_SRC)
	@mkdir -p $(VPI_DIR)
	@echo "Building VPI module..."
	iverilog-vpi --name=$(VPI_DIR)/verilog_python_interface $(VPI_SRC)
	@echo "VPI module built: $(VPI_LIB)"

# Compile Verilog simulation with VPI
.PHONY: compile
compile: vpi
	@echo "Compiling Verilog simulation..."
	cd $(SIM_DIR) && iverilog -o run_sim \
		-m ../$(VPI_DIR)/verilog_python_interface.vpi \
		tb_emotion_classifier.v ../$(SRC_DIR)/*.v
	@echo "Simulation compiled"

# Run emotion classification co-simulation
.PHONY: run-cosim
run-cosim: compile check-server
	@echo "Running emotion classification co-simulation..."
	@echo "Make sure Python AI server is running!"
	@echo "(Run 'make start-server' in another terminal)"
	cd $(SIM_DIR) && vvp -M../$(VPI_DIR) -mverilog_python_interface run_sim

# Run with specific image
.PHONY: run-image
run-image: compile check-server
	@if [ -z "$(IMAGE)" ]; then \
		echo "ERROR: Please specify IMAGE=<filename>"; \
		echo "Example: make run-image IMAGE=prepared_images/face_01.txt"; \
		exit 1; \
	fi
	@echo "Running co-simulation with image: $(IMAGE)"
	cd $(SIM_DIR) && vvp -M../$(VPI_DIR) -mverilog_python_interface run_sim +IMAGE=$(IMAGE)

# Run standard face detection (without emotion classification)
.PHONY: run-face-only
run-face-only:
	@echo "Running face detection only (no emotion classification)..."
	iverilog -o $(SIM_DIR)/run_sim $(TB_FACE) $(VERILOG_SRCS)
	vvp $(SIM_DIR)/run_sim

# Test the control FSM
.PHONY: test-fsm
test-fsm:
	@echo "Testing the control FSM..."
	iverilog -o $(SIM_DIR)/run_fsm_test $(SIM_DIR)/tb_control_fsm.v $(SRC_DIR)/control_fsm.v
	vvp $(SIM_DIR)/run_fsm_test

# Run all tests
.PHONY: test
test: test-fsm run-face-only
	@echo "All tests passed!"

# Start Python AI server
.PHONY: start-server
start-server:
	@if [ ! -f "$(EMOTION_MODEL)" ]; then \
		echo "ERROR: Emotion classification model not found at $(EMOTION_MODEL)"; \
		echo "Please download the model and place it in the models/ directory."; \
		exit 1; \
	fi
	@echo "Starting Python AI server with model: $(EMOTION_MODEL)"
	$(PYTHON) $(EMOTION_SERVER) --host 0.0.0.0 --port 8888 --model $(EMOTION_MODEL)

# Check if server is running
.PHONY: check-server
check-server:
	@echo "Checking if Python AI server is running..."
	@timeout 1 bash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/8888' 2>/dev/null || \
		(echo "WARNING: Python AI server not detected on port 8888"; \
		 echo "Start it with: make start-server"; \
		 echo "Continuing anyway...")

# Test all prepared images
.PHONY: test-all
test-all: compile check-server
	@echo "Testing all prepared images..."
	@for img in $(SIM_DIR)/prepared_images/face_*.txt; do \
		if [ -f "$$img" ]; then \
			echo ""; \
			echo "Testing: $$img"; \
			cd $(SIM_DIR) && vvp -M../$(VPI_DIR) -mverilog_python_interface run_sim +IMAGE=$$(basename $$img); \
		fi \
	done

# View waveforms
.PHONY: wave
wave:
	@if [ ! -f "$(SIM_DIR)/waveform.vcd" ]; then \
		echo "ERROR: No waveform file found. Run simulation first."; \
		exit 1; \
	fi
	@echo "Opening GTKWave..."
	cd $(SIM_DIR) && gtkwave waveform.vcd waveform.gtkw &

# Prepare test images
.PHONY: prepare-images
prepare-images:
	@echo "Preparing test images..."
	$(PYTHON) prepare_test_images.py

# Parse cascade data
.PHONY: parse-cascade
parse-cascade:
	@echo "Parsing Haar cascade XML..."
	$(PYTHON) parse_cascade.py

# Install Python dependencies
.PHONY: install-deps
install-deps:
	@echo "Installing Python dependencies..."
	pip install -r requirements.txt

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(VPI_OBJ) $(VPI_LIB)
	rm -f $(VPI_DIR)/*.vpi.o
	rm -f $(SIM_DIR)/run_sim
	rm -f $(SIM_DIR)/waveform.vcd
	rm -f $(SIM_DIR)/*.log
	@echo "Clean complete"

# Deep clean (including prepared images)
.PHONY: distclean
distclean: clean
	@echo "Deep cleaning..."
	rm -rf $(SIM_DIR)/prepared_images/*.txt
	rm -f $(DATA_DIR)/cascade_data.mem
	@echo "Deep clean complete"

# Help
.PHONY: help
help:
	@echo "=========================================="
	@echo "Emotion Classification Co-Simulation"
	@echo "=========================================="
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "Build targets:"
	@echo "  make vpi              - Build VPI module for Python communication"
	@echo "  make compile          - Compile Verilog with VPI"
	@echo "  make all              - Build everything"
	@echo ""
	@echo "Simulation and Verification targets:"
	@echo "  make start-server     - Start Python AI server (run in separate terminal)"
	@echo "  make run-cosim        - Run emotion classification co-simulation"
	@echo "  make run-image IMAGE=<file> - Run with specific image"
	@echo "  make run-face-only    - Run face detection only (no emotion)"
	@echo "  make test-fsm         - Test the control FSM"
	@echo "  make test             - Run all tests"
	@echo "  make test-all         - Test all prepared images with emotion"
	@echo "  make wave             - View waveforms in GTKWave"
	@echo ""
	@echo "Data preparation:"
	@echo "  make parse-cascade    - Parse Haar cascade XML to memory format"
	@echo "  make prepare-images   - Convert test images to Verilog format"
	@echo ""
	@echo "Setup:"
	@echo "  make install-deps     - Install Python dependencies"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean            - Remove build artifacts"
	@echo "  make distclean        - Deep clean (remove all generated files)"
	@echo ""
	@echo "Quick start:"
	@echo "  1. make install-deps"
	@echo "  2. make prepare-images"
	@echo "  3. make start-server      (in terminal 1)"
	@echo "  4. make run-cosim         (in terminal 2)"
	@echo ""

.PHONY: info
info:
	@echo "Configuration:"
	@echo "  Python: $(PYTHON)"
	@echo "  VPI directory: $(VPI_DIR)"
	@echo "  Source directory: $(SRC_DIR)"
	@echo "  Simulation directory: $(SIM_DIR)"
	@echo "  VPI library: $(VPI_LIB)"
