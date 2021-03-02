These are the files contained in the flash recovery image ("gordon") for encryption. Details..

* flash_update.sh - the script that gets executed by the init scripts on bootup. Contains the logic to flash the files from the USB key. Will call the partition script if it doesn't see a sda7 partition.
* automount.sh - script to automount USB keys.
* partition.sh - script to re-partition a fresh hard drive.
* drive.key - the LUKS encryption key for the encrypted partitions.
* fw-crypto.key - Key used to encrypt firmware updates
* fw-crypto-iv.key - Key used to encrypt firmware updates

To mount a partition using the LUKS key:
```
/usr/sbin/cryptsetup luksOpen -d /var/tmp/drive.key /dev/sda2 encroot
```

To decrypt a firmware update (note - the commands to get a text key and iv from the files included here are in flash_update.sh):
```
openssl enc -d -aes-256-cbc -K fe31ee754e16f552cbc04ede636038ff94a00bdd77aefb1ccde77c995b432380 -iv aae52ebc9ac21bc59db2dd23db7d6eb2 -in Orah_1.2.0.fw -out Orah_1.2.0.fw.dec
```
