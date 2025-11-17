#!/bin/bash
#iSolution multitouch
#xinput set-prop "WaveShare WS170120" --type=float "Coordinate Transformation Matrix" 0 1 0  -1 0 1 0 0 1
#https://wiki.ubuntu.com/X/InputCoordinateTransformation
xinput set-prop "iSolution multitouch" --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
xinput set-prop "iSolution multitouch Mouse" --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
export DISPLAY=:0
/usr/bin/xrandr --display :0.0 -o 
