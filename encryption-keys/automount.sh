#!/bin/bash

#automount basic script searching for /dev/sdb device -> should be usb key


if [ "$1" = "mount" ]
then
  echo "Checking USB key"
  for x in {b..k}
  do
    #if usb key has only one global partition
    if [ -e /dev/sd$x ]
    then
      mkdir /mnt/usb$x0
      mount /dev/sd$x /mnt/usb$x0
    fi

     for idx in {1..9}
     do
       if [ -e /dev/sd$x$idx ]
       then
      	 mkdir /mnt/usb$x$idx
      	 mount /dev/sd$x$idx /mnt/usb$x$idx
       fi
     done
  done
fi



if [ "$1" = "umount" ]
then
  
  for x in {b..k}
  do
    if [ -e /mnt/usb$x0 ]
    then
      umount /mnt/usb$x0
      rmdir /mnt/usb$x0
    fi

    for idx in {1..9}
    do
      if [ -e /mnt/usb$x$idx ]
      then
        umount /mnt/usb$x$idx
        rmdir /mnt/usb$x$idx
      fi
    done
  done
  echo "You can remove your usb key"
fi
