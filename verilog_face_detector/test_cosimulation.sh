#!/bin/bash
# test_cosimulation.sh
# Complete test script for emotion classification co-simulation

set -e  # Exit on error

echo "=========================================="
echo "Emotion Classification Co-Simulation Test"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check dependencies
echo "1. Checking dependencies..."
echo ""

# Check iverilog
if ! command -v iverilog &> /dev/null; then
    echo -e "${RED}ERROR: iverilog not found${NC}"
    echo "Install: sudo apt install iverilog"
    exit 1
else
    echo -e "${GREEN}✓ iverilog found${NC}"
fi

# Check iverilog-vpi
if ! command -v iverilog-vpi &> /dev/null; then
    echo -e "${RED}ERROR: iverilog-vpi not found${NC}"
    echo "Install: sudo apt install iverilog"
    exit 1
else
    echo -e "${GREEN}✓ iverilog-vpi found${NC}"
fi

# Check python3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}ERROR: python3 not found${NC}"
    echo "Install: sudo apt install python3"
    exit 1
else
    echo -e "${GREEN}✓ python3 found${NC}"
fi

# Check gcc
if ! command -v gcc &> /dev/null; then
    echo -e "${RED}ERROR: gcc not found${NC}"
    echo "Install: sudo apt install build-essential"
    exit 1
else
    echo -e "${GREEN}✓ gcc found${NC}"
fi

echo ""

# Check Python packages
echo "2. Checking Python packages..."
echo ""

MISSING_PACKAGES=""

python3 -c "import numpy" 2>/dev/null || MISSING_PACKAGES="${MISSING_PACKAGES}numpy "
python3 -c "import PIL" 2>/dev/null || MISSING_PACKAGES="${MISSING_PACKAGES}Pillow "
python3 -c "import lxml" 2>/dev/null || MISSING_PACKAGES="${MISSING_PACKAGES}lxml "

if [ -n "$MISSING_PACKAGES" ]; then
    echo -e "${YELLOW}WARNING: Missing Python packages: ${MISSING_PACKAGES}${NC}"
    echo "Install with: pip install ${MISSING_PACKAGES}"
    echo "Or run: make install-deps"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ All required Python packages found${NC}"
fi

echo ""

# Check TensorFlow (optional)
python3 -c "import tensorflow" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ TensorFlow available - can use real emotion models${NC}"
else
    echo -e "${YELLOW}ℹ TensorFlow not found - will use mock classifier${NC}"
    echo "  Install for real models: pip install tensorflow"
fi

echo ""

# Build VPI module
echo "3. Building VPI module..."
echo ""
make vpi
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ VPI module built successfully${NC}"
else
    echo -e "${RED}ERROR: VPI build failed${NC}"
    exit 1
fi

echo ""

# Check cascade data
echo "4. Checking cascade data..."
echo ""
if [ ! -f "data/cascade_data.mem" ]; then
    echo -e "${YELLOW}WARNING: cascade_data.mem not found${NC}"
    echo "Parsing cascade data..."
    make parse-cascade
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Cascade data parsed${NC}"
    else
        echo -e "${RED}ERROR: Cascade parsing failed${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Cascade data found${NC}"
fi

echo ""

# Check test images
echo "5. Checking test images..."
echo ""
IMAGE_COUNT=$(ls sim/prepared_images/face_*.txt 2>/dev/null | wc -l)
if [ $IMAGE_COUNT -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No prepared images found${NC}"
    echo "Preparing test images..."
    make prepare-images
    if [ $? -eq 0 ]; then
        IMAGE_COUNT=$(ls sim/prepared_images/face_*.txt 2>/dev/null | wc -l)
        echo -e "${GREEN}✓ Prepared ${IMAGE_COUNT} test images${NC}"
    else
        echo -e "${RED}ERROR: Image preparation failed${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Found ${IMAGE_COUNT} prepared images${NC}"
fi

echo ""

# Compile simulation
echo "6. Compiling Verilog simulation..."
echo ""
make compile
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Simulation compiled successfully${NC}"
else
    echo -e "${RED}ERROR: Compilation failed${NC}"
    exit 1
fi

echo ""

# Start Python server in background
echo "7. Starting Python AI server..."
echo ""
python3 emotion_server.py --host 0.0.0.0 --port 8888 > server.log 2>&1 &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"

# Wait for server to start
sleep 2

# Check if server is running
if ps -p $SERVER_PID > /dev/null; then
    echo -e "${GREEN}✓ Python AI server started${NC}"
else
    echo -e "${RED}ERROR: Server failed to start${NC}"
    cat server.log
    exit 1
fi

echo ""

# Run simulation
echo "8. Running co-simulation..."
echo ""
echo "Testing with first image..."
cd sim
timeout 60 vvp -M../vpi -mverilog_python_interface run_sim +IMAGE=prepared_images/face_01.txt
SIMULATION_RESULT=$?
cd ..

echo ""

# Check result
if [ $SIMULATION_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Simulation completed successfully${NC}"
    echo ""
    echo "=========================================="
    echo "All tests passed!"
    echo "=========================================="
    echo ""
    echo "You can now run:"
    echo "  make run-cosim          - Run single image"
    echo "  make test-all           - Test all images"
    echo "  make wave               - View waveforms"
    echo ""
elif [ $SIMULATION_RESULT -eq 124 ]; then
    echo -e "${RED}ERROR: Simulation timeout${NC}"
    echo "Check server.log and waveform.vcd for details"
else
    echo -e "${RED}ERROR: Simulation failed with code $SIMULATION_RESULT${NC}"
    echo "Check server.log for details"
fi

# Cleanup
echo "Stopping Python server..."
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true

echo ""
echo "Test complete!"

exit $SIMULATION_RESULT
