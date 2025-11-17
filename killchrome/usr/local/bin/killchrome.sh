#!/bin/bash
#
#  Kills all running chrome sessions
#
USERNAME=user
FLAGDIR=/home/${USERNAME}/kill_kiosk/
FLAGFILE="${FLAGDIR}stop.txt"
if [ ! -d $FLAGDIR ]; then
  mkdir $FLAGDIR
fi
# in this system an usb drive will be mounted under /media/username/drivename st
MYPENDRIVE="/media/${USERNAME}/STOP"
MYCHARNO=$(/usr/bin/lsblk  | grep ${MYPENDRIVE} | wc -c)
if [ $MYCHARNO -lt 1 ]; then
  if [ -f "$FLAGFILE" ]; then
    /usr/bin/killall chrome
    rm -f "$FLAGFILE"
  fi
else
  MYDRIVENAME="/dev/$(lsblk | grep STOP | head -n1 | sed -e 's/\s.*$//' | tr -cd '[:print:]')"
  /usr/bin/udisksctl unmount -b ${MYDRIVENAME} > /dev/null 2>&1
  /usr/bin/udisksctl power-off -b ${MYDRIVENAME} > /dev/null 2>&1
  /usr/bin/killall chrome
fi
exit 0
