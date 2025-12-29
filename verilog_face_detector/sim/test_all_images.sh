#!/bin/bash
set -euo pipefail

# Runs the Verilog face detector against all prepared images.
# Usage:
#   ./test_all_images.sh          # run all images
#   OPEN_WAVE=1 ./test_all_images.sh  # also open GTKWave after runs

SIM_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SIM_DIR"

PREP_DIR="prepared_images"
if ! compgen -G "${PREP_DIR}/face_*.txt" > /dev/null; then
	echo "No prepared images found in ${PREP_DIR}/. Run: python3 ../prepare_test_images.py"
	exit 1
fi

echo "Compiling testbench and RTL with Icarus Verilog..."
iverilog -g2012 -o run_sim tb_face_detector.v ../src/*.v

pass=0
fail=0

for img in ${PREP_DIR}/face_*.txt; do
	name="$(basename "$img")"
	echo "========================================"
	echo "Testing $name"
	echo "========================================"
	cp "$img" image.txt
	if vvp run_sim; then
		pass=$((pass+1))
	else
		fail=$((fail+1))
	fi
done

echo "\nSummary: ${pass} passed, ${fail} failed"

if [[ "${OPEN_WAVE:-0}" == "1" ]]; then
	if command -v gtkwave >/dev/null 2>&1; then
		echo "Opening GTKWave (waveform.vcd + waveform.gtkw)..."
		gtkwave waveform.vcd waveform.gtkw &
	else
		echo "GTKWave not found. Install it or open waveform.vcd manually."
	fi
fi