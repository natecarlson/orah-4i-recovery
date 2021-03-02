#!/bin/bash

#
# Partition creation script
#
echo "Create partition and format harddrive"

cat << EOF | /usr/sbin/gdisk /dev/sda
o #new table
y
n #part 1 EFI
1

+256M
ef00
n #rootfs
2

+7G

n #swap
3

+8G
8200
n #vs_server
5

+2G

n #var log
6

+5G

n #end of space partition
7



w
y
EOF



#FORMAT all partition created

####UEFI VFAT
/sbin/mkfs.vfat /dev/sda1

####ROOTFS SDA2
#luksformat
cat<<EOF | /usr/sbin/cryptsetup luksFormat /dev/sda2 /root/drive.key
YES
EOF
#luksmount
/usr/sbin/cryptsetup luksOpen -d /root/drive.key /dev/sda2 encroot
dd if=/dev/zero of=/dev/mapper/encroot
#cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/sda2
cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/mapper/encroot
y
EOF
#lusk umount
/usr/sbin/cryptsetup luksClose -d /root/drive.key encroot


#####SWAP
/sbin/mkswap /dev/sda3

#####VS DATA SDA5
#luksformat
cat<<EOF | /usr/sbin/cryptsetup luksFormat /dev/sda5 /root/drive.key
YES
EOF
#luksmount
/usr/sbin/cryptsetup luksOpen -d /root/drive.key /dev/sda5 encvs
dd if=/dev/zero of=/dev/mapper/encvs
#cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/sda5
cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/mapper/encvs
y
EOF
#lusk umount
/usr/sbin/cryptsetup luksClose -d /root/drive.key encvs


##########LOG SDA6
#luksformat
cat<<EOF | /usr/sbin/cryptsetup luksFormat /dev/sda6 /root/drive.key
YES
EOF
#luksmount
/usr/sbin/cryptsetup luksOpen -d /root/drive.key /dev/sda6 enclog
dd if=/dev/zero of=/dev/mapper/enclog
#cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/sda6
cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/mapper/enclog
y
EOF
#lusk umount
/usr/sbin/cryptsetup luksClose -d /root/drive.key enclog


#########PERSISTANT DATA SDA7
#luksformat
cat<<EOF|/usr/sbin/cryptsetup luksFormat /dev/sda7 /root/drive.key
YES
EOF
#luksmount
/usr/sbin/cryptsetup luksOpen -d /root/drive.key /dev/sda7 encdata
dd if=/dev/zero of=/dev/mapper/encdata
#cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/sda7
cat<<EOF | /usr/sbin/mkfs.ext4 -q /dev/mapper/encdata
y
EOF
#lusk umount
/usr/sbin/cryptsetup luksClose -d /root/drive.key encdata


echo "Harddrive is partitioned and formated"
