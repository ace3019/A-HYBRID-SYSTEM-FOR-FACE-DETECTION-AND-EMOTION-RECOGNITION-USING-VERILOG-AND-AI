# create_project.tcl
#
# This script creates a Vivado project for the Verilog Face Detector,
# synthesizes the design, and generates a bitstream.
#
# Usage:
#   vivado -mode batch -source create_project.tcl
#

# --- Configuration ---
# Project settings
set project_name "verilog_face_detector"
set project_dir "vivado_project"
set top_level_module "face_detector"

# Target FPGA device (change this to match your board)
set target_device "xc7z020clg484-1"

# Verilog source files
set verilog_sources [glob -nocomplain "src/*.v"]

# Constraints file
set xdc_file "src/face_detector.xdc"

# Memory initialization files
set cascade_coe_file "data/cascade_data.coe"
set feature_lut_coe_file "data/feature_lut.coe"

# --- Project Creation ---
puts "Creating Vivado project..."
create_project $project_name $project_dir -part $target_device -force

# Add Verilog source files
add_files -norecurse $verilog_sources

# Add constraints file
add_files -fileset constrs_1 -norecurse $xdc_file

# --- IP Core Generation ---
puts "Generating IP cores for ROMs..."

# Cascade ROM
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name cascade_rom_ip
set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File [file normalize $cascade_coe_file] \
    CONFIG.Use_MEM_Init {1} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Write_Depth_A {16384} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
] [get_ips cascade_rom_ip]

generate_target {instantiation_template} [get_ips cascade_rom_ip]
synth_ip [get_ips cascade_rom_ip]

# Feature LUT ROM
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name feature_lut_rom_ip
set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File [file normalize $feature_lut_coe_file] \
    CONFIG.Use_MEM_Init {1} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Write_Depth_A {16384} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
] [get_ips feature_lut_rom_ip]

generate_target {instantiation_template} [get_ips feature_lut_rom_ip]
synth_ip [get_ips feature_lut_rom_ip]

# --- Synthesis ---
puts "Synthesizing the design..."
update_compile_order -fileset sources_1
synth_design -top $top_level_module -part $target_device

# --- Implementation ---
puts "Implementing the design..."
opt_design
place_design
route_design
write_bitstream -force "${project_dir}/${project_name}.runs/impl_1/${project_name}.bit"

puts "Bitstream generated successfully."
puts "To run the design on a board, you will need to create a constraints file (.xdc) and map the top-level ports to the physical pins on the FPGA."
