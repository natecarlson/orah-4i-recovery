#!/bin/bash


#
# Flashing script that install linux system and videostitch data
#

sleep 6  #safety for slow usb


#create file for flashing status
/usr/sbin/cryptsetup luksOpen -d /root/drive.key /dev/sda7 encdata
mount /dev/mapper/encdata /mnt/data
mkdir -p /mnt/data/videostitch/
echo -n "KO" > /mnt/data/videostitch/flash



/root/automount.sh mount

found=false
flash_boot=false
flash_flash=false
flash_kern=false
flash_sys=false
flash_vs=false
fname_ext=""
fname=""

for x in {b..k}
do
  for idx in {0..9}
  do
    if [ -e /mnt/usb$x$idx ]
    then
#      if [ -f /mnt/usb$x$idx/Orah_*[0-9].fw ]
      fw_file=$(ls /mnt/usb$x$idx/Orah_*[0-9].fw 2> /dev/null)
      if [[ -n "$fw_file" ]]
      then
        echo -e "\n\nOrah Firmware found\n\n"
        found=true
	array=($fw_file)
	#decrypt
	key=$(cat /root/fw-crypto.key | xxd -p | tr -d \\n)
	iv=$(cat /root/fw-crypto-iv.key | xxd -p | tr -d \\n)
	fname_ext=${array[0]} 
	fname=$(basename ${fname_ext} .fw)
	if openssl enc -d -aes-256-cbc -K $key -iv $iv  -in $fname_ext -out /mnt/$fname.dec
	then
          tar xf /mnt/$fname.dec -C /mnt
	else
	  touch /mnt/usb$x$idx/ORAH_ERROR_FF1_wrong_firmware
	  echo -e "\n\nORAH ERROR FF1 Wrong Firmware\n\n"
	fi

	#format if hardrive is not already prepared	
        if [ ! -e /dev/sda7 ]
        then
	  /root/partition.sh
        fi


        #bootloader
        if [ -f /mnt/Orah/barebox.efi ]
        then 
	  if openssl dgst -sha512 -verify /root/flash_pub.key -signature /mnt/Orah/barebox.efis /mnt/Orah/barebox.efi 
	  then
            echo -e "\nFlash 1/5\n"
            mount /dev/sda1 /mnt/tmp
            if [ ! -e /mnt/tmp/EFI ]
            then
	      mkdir /mnt/tmp/EFI
	      mkdir /mnt/tmp/EFI/BOOT/
            fi
            cp /mnt/Orah/barebox.efi /mnt/tmp/EFI/BOOT/BOOTX64.EFI
            umount /mnt/tmp
            echo -e "\nFlash 1/5 done\n\n"
	    flash_boot=true
	  else
    	    touch /mnt/usb$x$idx/ORAH_ERROR_FF2_wrong_img
            echo -e "\nFlash 1/5 FF2 wrong image\n\n"
	  fi
        else
          echo -e "\nFlash 1/5 FF3 not found in firmware image\n\n"
        fi

        #minilinux flasher
        if [ -f /mnt/Orah/gordon ]
        then
	  if openssl dgst -sha512 -verify /root/flash_pub.key -signature /mnt/Orah/gordons /mnt/Orah/gordon
	  then
	    echo -e "\nFlash 2/5\n"
            mount /dev/sda1 /mnt/tmp
            cp /mnt/Orah/gordon /mnt/tmp/EFI/
            cp /mnt/Orah/gordon.sign /mnt/tmp/EFI/
            umount /mnt/tmp
            echo -e "\nFlash 2/5 done\n\n"
	    flash_flash=true
	  else
	    touch /mnt/usb$x$idx/ORAH_ERROR_FF4_wrong_img
            echo -e "\nFlash 2/5 FF4 wrong image\n\n"
	  fi
        else
          echo -e "\nFlash 2/5 FF5 not found in firmware image\n\n"
        fi
	


        #main img kernel
        if [ -f /mnt/Orah/orah ]
        then
	  if openssl dgst -sha512 -verify /root/flash_pub.key -signature /mnt/Orah/orahs /mnt/Orah/orah
	  then
            echo -e "\nFlash 3/5\n"
            mount /dev/sda1 /mnt/tmp
            cp /mnt/Orah/orah /mnt/tmp/EFI/
            cp /mnt/Orah/orah.sign /mnt/tmp/EFI/
            umount /mnt/tmp
            echo -e "\nFlash 3/5 done\n\n"
	    flash_kern=true
          else
	    touch /mnt/usb$x$idx/ORAH_ERROR_FF6_wrong_img
            echo -e "\nFlash 3/5 FF6 wrong image\n\n"
	  fi
	else
          echo -e "\nFlash 3/5 FF7 not found in firmware image\n\n"
        fi


        #linux  rootfs
        if [ -f /mnt/Orah/Orah.sys ]
        then
	  if openssl dgst -sha512 -verify /root/flash_pub.key -signature /mnt/Orah/Orah.syss /mnt/Orah/Orah.sys
	  then
            echo -e "\nFlash 4/5\n"
	    #wipefs
	    #luksformat
          #  cat<<EOF | /usr/sbin/cryptsetup luksFormat /dev/sda2 /root/drive.key
          #  YES
#EOF

	    #luksmount
            /usr/sbin/cryptsetup luksOpen -d /root/drive.key /dev/sda2 encroot
            #cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/sda2
            cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/mapper/encroot
            y
EOF
            #mount /dev/sda2 /mnt/tmp
            mount /dev/mapper/encroot /mnt/tmp
            tar xjf /mnt/Orah/Orah.sys  -C /mnt/tmp/
            umount /mnt/tmp
	    #lusk umount
            /usr/sbin/cryptsetup luksClose encroot
            echo -e "\nFlash 4/5 done\n\n"
	    flash_sys=true
	  else
	    touch /mnt/usb$x$idx/ORAH_ERROR_FF8_wrong_img
            echo -e "\nFlash 4/5 FF8 Wrong image\n\n"
	  fi
        else
          echo -e "\nFlash 4/5 FF9 not found in firmware image\n\n"
        fi

        #videostitch data
        if [ -f /mnt/Orah/Orah.img ]
        then
	  if openssl dgst -sha512 -verify /root/flash_pub.key -signature /mnt/Orah/Orah.imgs /mnt/Orah/Orah.img
	  then
            echo -e "\nFlash 5/5\n"
	    #wipefs
	    #luksformat
#            cat<<EOF | /usr/sbin/cryptsetup luksFormat /dev/sda5 /root/drive.key
#            YES
#EOF

	    #luksmount
            /usr/sbin/cryptsetup luksOpen -d /root/drive.key /dev/sda5 vsfs
            #cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/sda5
            cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/mapper/vsfs
            y
EOF
            #mount /dev/sda5 /mnt/tmp
            mount /dev/mapper/vsfs /mnt/tmp
            tar xjf /mnt/Orah/Orah.img  -C /mnt/tmp/
            umount /mnt/tmp
	    #luks umount
            /usr/sbin/cryptsetup luksClose vsfs
            echo -e "\nFlash 5/5 done\n\n"
	    flash_vs=true
	  else
	    touch /mnt/usb$x$idx/ORAH_ERROR_FF10_wrong_img
            echo -e "\nFlash 5/5 FF10 Wrong image\n\n"
	  fi
        else
          echo -e "\nFlash 5/5 FF11 not found in firmware image\n\n"
       fi

       rm -rf /mnt/Orah #not usefull as it is a ramfs....
       rm -rf /mnt/$fname.dec #not usefull as it is a ramfs....

       #filename=$(basename ${array[0]} .fw)
      # mv ${array[0]} /mnt/usb$x$idx/${filename}_done.fw

       break
     fi
   fi
 done
 if [ "$found"  = true ]
 then
   if $flash_boot && $flash_flash && $flash_kern && $flash_sys && $flash_vs
   then
     echo -n "OK" > /mnt/data/videostitch/flash
     mv ${fname_ext} /mnt/usb$x$idx/${fname}_done.fw
   else
     mv ${fname_ext} /mnt/usb$x$idx/${fname}_failed.fw
   fi
   break
 fi
done

#advise user if no firmware found
if [ "$found" = false ]
then
  echo -e "\n FF99 No Orah Firmware found\n\n"
fi


#closing flashing status file
umount /mnt/data
/usr/sbin/cryptsetup luksClose encdata


/root/automount.sh umount


sleep 6
reboot
