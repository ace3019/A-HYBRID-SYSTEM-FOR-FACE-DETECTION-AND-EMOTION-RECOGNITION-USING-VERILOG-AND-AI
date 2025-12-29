# face_detector.xdc
#
# This is a template constraints file for the Verilog Face Detector.
# You will need to modify this file to match the specific pinout of your
# target Xilinx board.
#
# To use this file, you will need to:
#   1. Uncomment the lines for the ports you want to constrain.
#   2. Replace the placeholder package pins (e.g., "PIN_XX") with the actual
#      package pins for your board.
#   3. Add this file to your Vivado project.
#

# --- Clock and Reset ---
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports clk ]
# create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
#
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports rst ]

# --- Image Input ---
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { pixel_in[7] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { pixel_in[6] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { pixel_in[5] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { pixel_in[4] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { pixel_in[3] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { pixel_in[2] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { pixel_in[1] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { pixel_in[0] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports pixel_valid ]

# --- Detection Output ---
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports face_detected ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_x[7] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_x[6] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_x[5] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_x[4] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_x[3] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_x[2] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_x[1] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_x[0] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_y[7] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_y[6] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_y[5] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_y[4] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_y[3] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_y[2] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_y[1] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_y[0] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_scale[7] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_scale[6] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_scale[5] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_scale[4] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_scale[3] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_scale[2] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_scale[1] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports { face_scale[0] } ]
# set_property -dict { PACKAGE_PIN "PIN_XX" IOSTANDARD "LVCMOS33" } [get_ports done ]
