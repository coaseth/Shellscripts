#!/usr/bin/python3

# History:
# 2024/06/12: supervision of the comments and extended function to dedicated probing
# 2024/05/30: additional input parameters for processor.py included, measure point's thickness matches the first layer's struts' height and the other way around
# 2024/04/30: trying out the new options.ini variables, setting up admesh
# 2024/04/26-29: replacing statically generated profilenames and making it flexible, giving a request to the frontend's update with variables according to our needs.
# 2024/04/23: making it work with web-gui and replace older render.sh



#Developed by and at DUPLEX3D Gmbh.
#Developer- Molnár Csanád
#Starting date 2024/04/23

import argparse
import os
import shutil
import subprocess
import glob
import re, json
from PIL import Image, ImageDraw, ImageFilter



def main(args):

    os.chdir("Render")
    #print(f"cwd: {os.getcwd()}")
    
    
    def remove_files(output_dir=None):
        if output_dir is None:
            output_dir = os.getcwd()
        neededgcodename=[]
        for x in {updated_vars['input']}:
            neededgcodename.append(x)
            namef=neededgcodename[0].split('.stl')
            gcodename=namef[0]+(".gcode")

        files_to_keep = [
           "upper.gcode",
           "lower.gcode",
           "combo.gcode",
           "probePoints.csv",
           "lower.stl",
           "struts.gcode",
        ]
    # Define default values for variables
    default_values = { }
    for i,k in enumerate("layerheight renderprofile_directory output_directory input projectname".split(" ") ):
       #print(i,k)
       #print("  ",args[i])
       default_values[k] = args[i]
    print("Def dictionary",default_values)
    #checking slicer profile's type 
    tester=str(default_values['renderprofile_directory']).strip()
    slicer_profile_up=tester+"/paramfile_1.ini"
    slicer_profile_down=tester+"/paramfile_2.ini"
    #--------------------------------------------------------------------------------------------------
    
    existing_vars = { 
      "slicer_profile": slicer_profile_up,
      "lower_slicer_profile": slicer_profile_down,
      "slicer": "/usr/src/grante3d2/bin/prusa-root/usr/bin/bin/prusa-slicer",
      "common_support":"True",
    }
         
    # Update existing variables with default values if missing
    updated_vars = {**default_values, **existing_vars}
    #getting the lower stl/gcode ready
    neededstlname=[]
    for x in {updated_vars['input']}:
        neededstlname.append(x)
        stlname=neededstlname[0]
    #/usr/src/grante3d2/g3dc2/docroot/files/projects/rendertesting8/rendertesting8-scene.stl --->file path to the scene provided.
    subprocess.run(['admesh','--xy-mirror','-b','lower.stl',stlname])
    
    #--------------------------------------------------------------------------------------------------
    
    options_ini_path = "options.ini"
    
    #OPTIONS_INI PARSING WITHIN OUTPUT DIRECTORY
    opti=str(default_values['output_directory']).strip()
    options2_ini_path=opti+"/options.ini"
    
    def parse_ini_file(file_path):
        data = {}
        with open(file_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'): # Ignore empty lines and comments
                    key,value=line.split('=')
                    data[key]=value
            keys = data.keys()
            values = data.values()
        return data

    parsed_data = parse_ini_file(options2_ini_path)

    parsed_data2=parse_ini_file(options_ini_path)
    parsed_dd={**parsed_data2, **parsed_data}
    par={"common_support":"True"}
    parsed_dd={**par,**parsed_dd}
    parsed_dd["custom_support_wall"] = parsed_dd.pop("custom_skirt")
    #--------------------------------------------------------------------------------------------------
    #Creating options.gui
    gui=(opti+"/gui.ini")
    
    gui_data1=str(updated_vars['slicer_profile']).strip()
    gui_data_combined_up=(gui_data1+","+gui)
    
    gui_data2=str(updated_vars['lower_slicer_profile']).strip()
    gui_data_combined_down=(gui_data2+","+gui)
    
    def create_gui_ini(parsed_data, output_dir):
        gui_ini_path = os.path.join(output_dir, "gui.ini")
        with open(gui_ini_path, 'w') as f:
            f.write(f"perimeters={parsed_data.get('perimeters', '')}\n")
            f.write(f"fill_density={parsed_data.get('fill_density', '')}\n")
            f.write(f"fill_pattern={parsed_data.get('fill_pattern', '')}\n")
            f.write(f"top_solid_layers={parsed_data.get('top_solid_layers', '')}\n")
            f.write(f"bottom_solid_layers={parsed_data.get('bottom_solid_layers', '')}\n")
            f.write(f"support_material_spacing={parsed_data.get('support_material_spacing', '')}\n")
            f.write(f"support_material_interface_layers={parsed_data.get('support_material_interface_layers', '')}\n")

    #--------------------------------------------------------------------------------------------------
    
    #re-checking slicer profile's type 
    tester=str(updated_vars['renderprofile_directory']).strip()
    slicer_profile_up=tester+"/paramfile_1.ini"
    slicer_profile_down=tester+"/paramfile_2.ini"
    #--------------------------------------------------------------------------------------------------
    
    
    # Write updated variables to options.ini
    with open(options_ini_path, 'w') as f:
        for var_name, var_value in updated_vars.items():
            f.write(f"{var_name}={var_value}\n")
    #--------------------------------------------------------------------------------------------------
    
    
    # Check if the output directory exists, create it if not
    output_dir = updated_vars.get('output_directory', 'placeholder')
    if output_dir != 'placeholder' and not os.path.exists(output_dir):
        os.makedirs(output_dir)
    #print(slicer_profile_up,slicer_profile_down)
    #--------------------------------------------------------------------------------------------------
    
    #updating the dictionary variable
    updated_vars.update(slicer_profile=slicer_profile_up)
    updated_vars.update(lower_slicer_profile=slicer_profile_down)
    parsed_dd['slicer_profile']=gui_data_combined_up
    parsed_dd['lower_slicer_profile']=gui_data_combined_down
    #--------------------------------------------------------------------------------------------------
    

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
    print(processor_vars)
    subprocess.run(['python3','/usr/src/grante3d2/Render/processor.py', stlname, *processor_vars])
    #print("parsed_dd:", parsed_dd)
    #print("updated_vars", updated_vars)
    #print("proc_vars:",processor_vars)
    #--------------------------------------------------------------------------------------------------
    
    #if processor.py's output exists, rename it to upper.gcode
    if os.path.exists("combo.gcode"):
       os.rename("combo.gcode", "upper.gcode")
    
    # Move files to the output directory
    files_to_move = [
        "lower.gcode",
        "upper.gcode",
        "combo.gcode",
        "probePoints.csv",
        "lower.stl",
        "struts.gcode",
    ]
    #move the necessary files into the output directory where no files found, print error message (no interruption)
    for file_name in files_to_move:
        source_path = os.path.join(os.getcwd(), file_name)
        dest_path = os.path.join(output_dir, file_name)
        try:
            shutil.move(source_path, dest_path)
        except FileNotFoundError:
            print(f"Error: {file_name} not found. Skipping...")
            continue
    #--------------------------------------------------------------------------------------------------
    
    create_gui_ini(parsed_data, output_dir)
        
    probe_file1="--probe_file="+output_dir+'/probePoints.csv'
    fnm=output_dir+'/upper.gcode'
    subprocess.run(['python3','/usr/src/grante3d2/DedicatedProbing/dedicated_probing',probe_file1 ,fnm])
    
    remove_files()  #calling again to remove the processor's not needed output

    print("\n","\n","Successfully sliced, You can start uploading!","\n","\n")
    
    
    
    """ 
    print("starting prusa update possibly")
    # path to prusa: /usr/bin/prusa-slicer"
    os.chdir("/usr/bin/")
    subprocess.run(['apt','install','-y','prusa-slicer'])
    """

if __name__ == "__main__":
    import sys
    #installing dependencies, only enable once before running.
    #subprocess.run(['apt','-y','install','cmake','libeigen3-dev'])
    #subprocess.run(['pip3','install','pyclipr','shapely','setuptools','eigen','fmt','scipy','scikit-learn','tqdm', 'colorama', 'termcolor','Pillow'])
    #--------------------------------------------------------------------------------------------------
    main(sys.argv[1:])
