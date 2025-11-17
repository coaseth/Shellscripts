#!/usr/bin/python3
import argparse
import os
import shutil
import subprocess
import glob
import re, json



def main(args):
    #"/usr/src/grante3d2/bin/prusa-root/usr/bin/bin/profiles/"
    default_values= {
        "renderprofile_directory": "/usr/src/grante3d2/g3dc2/docroot/files/renderprofiles/PLA_NOSUPPORT",
        "slicer_profile": "",
        "lower_slicer_profile": "",
        "slicer": "/usr/src/grante3d2/bin/prusa-root/usr/bin/bin/prusa-slicer", 
        "brace": True,
        "custom_support_wall": True
    }

    stlname="/usr/src/grante3d2/g3dc2/docroot/files/projects/kanu/kanu-scene.stl"
    #setting up the slicer profile with paramfile_1 being the upper, paramfile_2 being the lower profile for the slicer
    tester=str(default_values['renderprofile_directory']).strip()
    slicer_profile_up=tester+"/paramfile_1.ini"
    slicer_profile_down=tester+"/paramfile_2.ini"

    default_values.update(slicer_profile=slicer_profile_up)
    default_values.update(lower_slicer_profile=slicer_profile_down)
    print("default values dictionary ===> ", default_values)

    #--------------------------------------------------------------------------------------------------

    subprocess.run(['admesh','--xy-mirror','-b','lower.stl',stlname])
    #--------------------------------------------------------------------------------------------------    

    # Variables for Processor.py, Run the processor script

    processor_vars = [
        f"--slicer_profile={default_values['slicer_profile']}",
        f"--lower_slicer_profile={default_values['lower_slicer_profile']}",
        f"--slicer={default_values['slicer']}",
        f"--brace={default_values['brace']}",
        f"--custom_support_wall={default_values['custom_support_wall']}",
    ]
    print(processor_vars)
    subprocess.run(['python3','/usr/src/grante3d2/Render/processor.py', stlname, *processor_vars])
    #--------------------------------------------------------------------------------------------------
    
    #if processor.py's output exists, rename it to upper.gcode
    if os.path.exists("combo.gcode"):
       os.rename("combo.gcode", "upper.gcode")

    print("\n","\n","Successfully sliced, You can start uploading!","\n","\n")

if __name__ == "__main__":
    import sys
    #installing dependencies, only enable once before running.
    #subprocess.run(['apt','-y','install','cmake','libeigen3-dev'])
    #subprocess.run(['pip3','install','pyclipr','shapely','setuptools','eigen','fmt','scipy','scikit-learn','tqdm', 'colorama', 'termcolor','Pillow'])
    #--------------------------------------------------------------------------------------------------
    main(sys.argv[1:])
