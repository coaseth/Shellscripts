"lsusb" kiírja, hogy milyen hozzákapcsolt eszközök találhatóak a gépben, itt található a kijelző típusa (pl.:iSolution T214WI02+000)

Ha esetleg ez nem adna választ, akkor :
"/home/user"-ben     "bash displaycheck.sh"




Kijelzőtípus megkeresése szükséges, hogy milyen fajta benne a kijelző, ahhoz tartozó script kell feltöltésre
Displaycheck, ha "lsusb" nem megy
#!/bin/bash

for sysdevpath in $(find /sys/bus/usb/devices/usb*/ -name dev); do
    (
        syspath="${sysdevpath%/dev}"
        devname="$(udevadm info -q name -p $syspath)"
        [[ "$devname" == "bus/"* ]] && exit
        eval "$(udevadm info -q property --export -p $syspath)"
        [[ -z "$ID_SERIAL" ]] && exit
        echo "/dev/$devname - $ID_SERIAL"
    )
done

-------------------------------------------

Egyik fájl:

/home/user/.config/autostart/mytouchpad.desktop
tartalma:

------------------------------------
[Desktop Entry]
Type=Application
Name=mytouchpad
Comment=Rotate touchpad script
Exec=/home/user/.config/mytouchpad.sh

---------------------------------------------------------------------------------------------------------------

Másik fájl: 

/home/user/.config/mytouchpad.sh          
tartalma:

------------------------------------------------------------------------------------------------------------------

#!/bin/bash
#iSolution multitouch
#xinput set-prop "WaveShare WS170120" --type=float "Coordinate Transformation Matrix" 0 1 0  -1 0 1 0 0 1
#https://wiki.ubuntu.com/X/InputCoordinateTransformation
xinput set-prop "iSolution T214WI02+000" --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
xinput set-prop "iSolution T214WI02+000 Mouse" --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
export DISPLAY=:0
/usr/bin/xrandr --display :0.0 -o 

------------------------------------------------------------------------------------------------------------------

#!/bin/bash
#iSolution multitouch
#xinput set-prop "WaveShare WS170120" --type=float "Coordinate Transformation Matrix" 0 1 0  -1 0 1 0 0 1
#https://wiki.ubuntu.com/X/InputCoordinateTransformation
xinput set-prop "iSolution multitouch" --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
xinput set-prop "iSolution multitouch Mouse" --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
export DISPLAY=:0
/usr/bin/xrandr --display :0.0 -o 

------------------------------------------------------------------------------------------------------------------
kijelzőtől függően ittvan, hogy mi kell hozzá.
