import struct
from lxml import etree
import os

# Fixed-point configuration
FIXED_POINT_BITS = 32
FIXED_POINT_FRAC = 16
FIXED_POINT_SCALE = 2**FIXED_POINT_FRAC

def float_to_fixed_point(val):
    """Converts a float to a Q16.16 fixed-point integer."""
    return int(val * FIXED_POINT_SCALE)

def to_hex(val):
    """Converts a signed integer to a 32-bit hex string."""
    return format(val & 0xFFFFFFFF, '08x')

def parse_xml(xml_file):
    """Parses the Haar cascade XML file and returns the stages and features."""
    print(f"Parsing {xml_file}...")
    tree = etree.parse(xml_file)
    root = tree.getroot()

    cascade = root.find('.//cascade')
    if cascade is None:
        raise ValueError("Error: Could not find cascade in XML")

    width = int(cascade.find('width').text)
    height = int(cascade.find('height').text)
    print(f"Base window size: {width}x{height}")

    features_elem = cascade.find('features')
    feature_list = features_elem.findall('_')
    print(f"Found {len(feature_list)} features")

    features = []
    for feature in feature_list:
        rects = feature.find('rects')
        rect_list = rects.findall('_')
        
        feature_rects = []
        for rect in rect_list:
            rect_data = rect.text.strip().split()
            x, y, w, h = map(int, rect_data[:4])
            weight = float(rect_data[4].rstrip('.'))
            feature_rects.append((x, y, w, h, weight))
        features.append(feature_rects)

    stages_elem = cascade.find('stages')
    stage_list = stages_elem.findall('_')
    print(f"Found {len(stage_list)} stages")

    return stage_list, features, width, height

def write_mem_file(mem_file, stages, features, width, height):
    """Writes the cascade data to a .mem file."""
    print(f"Writing to {mem_file}...")
    with open(mem_file, 'w') as f:
        f.write(f"// Haar Cascade Data for Face Detection\n")
        f.write(f"// Number of stages: {len(stages)}\n")
        f.write(f"// Number of features: {len(features)}\n")
        f.write(f"// Base window: {width}x{height}\n")
        f.write(f"// Format: Fixed-point Q16.16\n\n")

        total_weak_classifiers = 0
        for stage_idx, stage in enumerate(stages):
            stage_threshold = float(stage.find('stageThreshold').text)
            stage_threshold_hex = to_hex(float_to_fixed_point(stage_threshold))
            f.write(f"// Stage {stage_idx}\n")
            f.write(f"{stage_threshold_hex}\n")

            classifiers = stage.find('weakClassifiers').findall('_')
            f.write(f"{len(classifiers):08x}\n")
            total_weak_classifiers += len(classifiers)

            for classifier in classifiers:
                internal_data = classifier.find('internalNodes').text.strip().split()
                feature_idx = int(internal_data[2])
                threshold = float(internal_data[3])

                leaf_data = classifier.find('leafValues').text.strip().split()
                left_val = float(leaf_data[0])
                right_val = float(leaf_data[1])

                feature_idx_hex = to_hex(feature_idx)
                threshold_hex = to_hex(float_to_fixed_point(threshold))
                left_hex = to_hex(float_to_fixed_point(left_val))
                right_hex = to_hex(float_to_fixed_point(right_val))
                f.write(f"{feature_idx_hex} {threshold_hex} {left_hex} {right_hex}\n")
            f.write("\n")

        # This part of the file is not used by the Verilog code,
        # but we'll keep it for debugging purposes.
        f.write("// === FEATURES SECTION (for debugging) ===\n")
        for feat_idx, feature_rects in enumerate(features):
            f.write(f"// Feature {feat_idx}\n")
            f.write(f"{len(feature_rects):08x}\n")
            for x, y, w, h, weight in feature_rects:
                weight_hex = to_hex(float_to_fixed_point(weight))
                f.write(f"{x:08x} {y:08x} {w:08x} {h:08x} {weight_hex}\n")
            f.write("\n")
    print(f"Total weak classifiers: {total_weak_classifiers}")

def write_coe_file(coe_file, stages, features, width, height):
    """Writes the cascade data to a .coe file."""
    print(f"Writing to {coe_file}...")
    with open(coe_file, 'w') as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")

        all_data = []
        for stage_idx, stage in enumerate(stages):
            stage_threshold = float(stage.find('stageThreshold').text)
            all_data.append(to_hex(float_to_fixed_point(stage_threshold)))

            classifiers = stage.find('weakClassifiers').findall('_')
            all_data.append(to_hex(len(classifiers)))

            for classifier in classifiers:
                internal_data = classifier.find('internalNodes').text.strip().split()
                feature_idx = int(internal_data[2])
                threshold = float(internal_data[3])

                leaf_data = classifier.find('leafValues').text.strip().split()
                left_val = float(leaf_data[0])
                right_val = float(leaf_data[1])

                all_data.append(to_hex(feature_idx))
                all_data.append(to_hex(float_to_fixed_point(threshold)))
                all_data.append(to_hex(float_to_fixed_point(left_val)))
                all_data.append(to_hex(float_to_fixed_point(right_val)))

        f.write(",\n".join(all_data))
        f.write(";\n")

def write_feature_lut_files(mem_file, coe_file, features):
    """Writes the feature lookup table to .mem and .coe files."""
    print(f"Writing feature LUT to {mem_file} and {coe_file}...")
    
    with open(mem_file, 'w') as f_mem, open(coe_file, 'w') as f_coe:
        f_coe.write("memory_initialization_radix=16;\n")
        f_coe.write("memory_initialization_vector=\n")

        all_data_coe = []
        for feature_rects in features:
            f_mem.write(f"{len(feature_rects):08x}\n")
            all_data_coe.append(to_hex(len(feature_rects)))

            for x, y, w, h, weight in feature_rects:
                weight_fp = float_to_fixed_point(weight)
                f_mem.write(f"{x:08x} {y:08x} {w:08x} {h:08x} {to_hex(weight_fp)}\n")
                
                all_data_coe.append(to_hex(x))
                all_data_coe.append(to_hex(y))
                all_data_coe.append(to_hex(w))
                all_data_coe.append(to_hex(h))
                all_data_coe.append(to_hex(weight_fp))
        
        f_coe.write(",\n".join(all_data_coe))
        f_coe.write(";\n")

import os

def main():
    """Main function."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    xml_file = os.path.join(script_dir, 'data/haarcascade_frontalface_default.xml')
    cascade_mem_file = os.path.join(script_dir, 'data/cascade_data.mem')
    cascade_coe_file = os.path.join(script_dir, 'data/cascade_data.coe')
    feature_mem_file = os.path.join(script_dir, 'data/feature_lut.mem')
    feature_coe_file = os.path.join(script_dir, 'data/feature_lut.coe')

    try:
        stages, features, width, height = parse_xml(xml_file)
        
        write_mem_file(cascade_mem_file, stages, features, width, height)
        write_coe_file(cascade_coe_file, stages, features, width, height)
        write_feature_lut_files(feature_mem_file, feature_coe_file, features)
        
        print("\nParsing complete!")
        print(f"Output files generated:")
        print(f"  - {cascade_mem_file}")
        print(f"  - {cascade_coe_file}")
        print(f"  - {feature_mem_file}")
        print(f"  - {feature_coe_file}")

    except (FileNotFoundError, ValueError) as e:
        print(f"Error: {e}")
        exit(1)

if __name__ == '__main__':
    main()
