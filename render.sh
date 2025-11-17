#!/usr/bin/python3
#howitran 1=Good ; 2=Good, no brace ; 3=File not found 4=Couldn't read file- ; 5=Error writing gui.ini ; 6=Brace not found, but needed ; 7=No gcode generated ; 8=valid STL ; 9=invalid STL ; 10=admesh error
import argparse
import os
import shutil
import subprocess
import logging

from stl import mesh


# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def create_gui_ini(parsed_data, output_dir):
    """Create gui.ini file based on parsed_data."""
    gui_ini_path = os.path.join(output_dir, "gui.ini")
    try:
        with open(gui_ini_path, 'w') as f:
            f.write(f"perimeters={parsed_data.get('perimeters', '')}\n")
            f.write(f"fill_density={parsed_data.get('fill_density', '')}\n")
            f.write(f"fill_pattern={parsed_data.get('fill_pattern', '')}\n")
            f.write(f"top_solid_layers={parsed_data.get('top_solid_layers', '')}\n")
            f.write(f"bottom_solid_layers={parsed_data.get('bottom_solid_layers', '')}\n")
            f.write(f"support_material_spacing={parsed_data.get('support_material_spacing', '')}\n")
            f.write(f"support_material_interface_layers={parsed_data.get('support_material_interface_layers', '')}\n")
    except Exception as e:
        logging.error(f"Error writing file {gui_ini_path}: {e}")
        howitran=5
        with open("error_code.log", 'w') as file:
            file.write(str(howitran))

def parse_ini_file(file_path):
    """Parse .ini file into a dictionary."""
    data = {}
    try:
        with open(file_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):  # Ignore empty lines and comments
                    key, value = line.split('=')
                    data[key] = value
    except FileNotFoundError:
        logging.error(f"File not found: {file_path}")
        lg()
        
    except Exception as e:
        logging.error(f"Error reading file {file_path}: {e}")
        lg()
    return data

def main(args):
    try:
        howitran=0
        def lg():
            with open("error_code.log", 'w') as file:
                    file.write(str(howitran))
                    print(howitran)
                    exit(howitran)
        
        os.chdir("Render")
        logging.info("Changed directory to Render.")
        
        # Define default values for variables
        default_values = {}
        for i, k in enumerate("layerheight renderprofile_directory output_directory input projectname".split(" ")):
            default_values[k] = args[i]

        # Checking slicer profile's type
        tester = str(default_values['renderprofile_directory']).strip()
        slicer_profile_up = os.path.join(tester, "paramfile_1.ini")
        slicer_profile_down = os.path.join(tester, "paramfile_2.ini")

        # Existing variables
        existing_vars = { 
            "slicer_profile": slicer_profile_up,
            "lower_slicer_profile": slicer_profile_down,
            "slicer": "/usr/src/grante3d2/bin/prusa-root/usr/bin/bin/prusa-slicer",
            "common_support": "True",
        }

        # Update existing variables with default values if missing
        global updated_vars
        updated_vars = {**default_values, **existing_vars}
        
        stlname = updated_vars['input']
        # Load the STL file
        stl_mesh = mesh.Mesh.from_file(stlname)
        # Perform some basic checks
        if stl_mesh.vectors.size == 0:
            howitran=9
            print("The STL file contains no vectors.", "Error code: ",howitran)
            lg()
        # Check if all vectors have exactly 3 vertices
        for vector in stl_mesh.vectors:
            if vector.shape != (3, 3):
                howitran=9
                print("Invalid vector shape detected.", "Error code: ", howitran)
                lg()
        if howitran in [0, 1, 2, 3, 4, 5, 6]:
            logging.info(f"Running admesh for {stlname}.")
            subprocess.run(['admesh', '--xy-mirror', '-b', 'lower.stl', stlname], check=True)
        elif howitran in [8, 9]:
            pass
        # Parsing options.ini within output directory
        opti = str(default_values['output_directory']).strip()
        options2_ini_path = os.path.join(opti, "options.ini")
        parsed_data = parse_ini_file(options2_ini_path)
        parsed_data2 = parse_ini_file("options.ini")
        parsed_dd = {**parsed_data2, **parsed_data, "common_support": "True"}
        parsed_dd["custom_support_wall"] = parsed_dd.pop("custom_skirt", "")

        # Creating options.gui
        gui = os.path.join(opti, "gui.ini")
        gui_data_combined_up = f"{updated_vars['slicer_profile']},{gui}"
        gui_data_combined_down = f"{updated_vars['lower_slicer_profile']},{gui}"

        # Write updated variables to options.ini
        with open("options.ini", 'w') as f:
            for var_name, var_value in updated_vars.items():
                f.write(f"{var_name}={var_value}\n")

        # Check if the output directory exists, create it if not
        output_dir = updated_vars.get('output_directory', 'placeholder')
        if output_dir != 'placeholder' and not os.path.exists(output_dir):
            os.makedirs(output_dir)
            logging.info(f"Created output directory")

        # Updating the dictionary variable
        updated_vars.update(slicer_profile=slicer_profile_up)
        updated_vars.update(lower_slicer_profile=slicer_profile_down)
        parsed_dd['slicer_profile'] = gui_data_combined_up
        parsed_dd['lower_slicer_profile'] = gui_data_combined_down

        
        # Usage
        file_path=stlname
        # Variables for Processor.py, Run the processor script
        processor_vars = [
            f"--slicer_profile={parsed_dd['slicer_profile']}",
            f"--lower_slicer_profile={parsed_dd['lower_slicer_profile']}",
            f"--slicer={parsed_dd['slicer']}",
            f"--support_height={parsed_dd['support_height']}",
            f"--support_distance={parsed_dd['support_distance']}",
            f"--support_lines={parsed_dd['support_lines']}",
            f"--strut_lines={parsed_dd['strut_lines']}",
            f"--strut_horizontal_spacing={parsed_dd['strut_horizontal_spacing']}",
            f"--strut_vertical_spacing={parsed_dd['strut_vertical_spacing']}",
            f"--measure_point_dia={parsed_dd['measure_point_dia']}",
            f"--measure_point_thickness={parsed_dd['measure_point_thickness']}",
            f"--brace={parsed_dd['brace']}",
            f"--brace_big_struts={parsed_dd['brace_big_struts']}",
            f"--common_support={parsed_dd['common_support']}",
            f"--custom_support_wall={parsed_dd['custom_support_wall']}",
            f"--strut_thickness_first_layer={parsed_dd['measure_point_thickness']}",
            f"--lower_support_base_thickness={parsed_dd['measure_point_thickness']}"
        ]
        logging.info(f"Running processor")
        subprocess.run(['python3', '/usr/src/grante3d2/Render/processor.py', stlname, *processor_vars], check=True)

        create_gui_ini(parsed_dd, output_dir)

        #probe_file1 = f"--probe_file={os.path.join(output_dir, 'probePoints.csv')}"
        fnm = os.path.join(output_dir, 'upper.gcode')
        #logging.info(f"Running dedicated probing.")
        #subprocess.run(['python3', '/usr/src/grante3d2/DedicatedProbing/dedicated_probing', probe_file1, fnm], check=True)

        #remove_files(output_dir)  # Calling again to remove the processor's not needed output

        # If processor.py's output exists, rename it to upper.gcode
        if os.path.exists("combo.gcode"):
            os.rename("combo.gcode", "upper.gcode")

        # Check if brace.gcode is present in the BraceGeneration folder
        brace_generation_dir = os.path.join(os.getcwd(), 'BraceGeneration')
        brace_gcode_exists = os.path.isfile(os.path.join(brace_generation_dir, 'brace.gcode'))
        upper_gcode_exists = os.path.isfile(os.path.join(os.getcwd(), 'upper.gcode'))
        lower_gcode_exists = os.path.isfile(os.path.join(os.getcwd(), 'lower.gcode'))

        #1=good, 2=no brace, 99=no brace, but expected, 100=no gcode
        if parsed_dd.get('brace', 'false') == 'true':
            # Check for brace.gcode, upper.gcode, and lower.gcode
            if brace_gcode_exists and upper_gcode_exists and lower_gcode_exists:
                howitran=1
                logging.info("Successfully sliced and generated upper,brace.gcode. You can start uploading!")
            else:
                howitran=6
                logging.error("Error: brace.gcode not found or missing required gcode files.")
        else:
            # Only check for upper.gcode
            if upper_gcode_exists:
                howitran=1
                logging.info("Successfully sliced and generated upper.gcode. You can start uploading!")
            else:
                howitran=7
                logging.error("Error: upper.gcode not found.")

        # Move files to the output directory
        files_to_move = [
            "lower.gcode",
            "upper.gcode",
            "probePoints.csv",
            "lower.stl",
            "struts.gcode",
            ]
        for file_name in files_to_move:
            source_path = os.path.join(os.getcwd(), file_name)
            dest_path = os.path.join(output_dir, file_name)
            try:
                shutil.move(source_path, dest_path)
            except FileNotFoundError:
                logging.error(f"Error: {file_name} not found. Skipping...")


    except subprocess.CalledProcessError as e:
        logging.error(f"Subprocess error: {e}")
        return False
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}")
        return False
    lg()

    print("\n","\n","Successfully sliced, You can start uploading!","\n","\n")
    
if __name__ == "__main__":
    import sys
    #installing dependencies, only enable once before running.
    #subprocess.run(['apt','-y','install','cmake','libeigen3-dev'])
    #subprocess.run(['pip3','install','pyclipr','shapely','setuptools','eigen','fmt','scipy','scikit-learn','tqdm', 'colorama', 'termcolor','Pillow', 'numpy-stl'])
    #--------------------------------------------------------------------------------------------------
    main(sys.argv[1:])

