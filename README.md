# Orah 4i Stiching Box Recovery

Orah (previously known as VideoStitch) made a product called the Orah 4i, which includes a 360 camera (using 4 syncronized cameras that output RTSP over ethernet) and a stitching box that could both record and livestream via RTMP. They went under a few years ago. Most of their codebase is now available as open source via the [stitchEm project](https://github.com/stitchEm/stitchEm) project (including most of the stitching box's requirements too), but this isn't much of a help to people who already own a stitching box but don't have the proper software for it. As the company has gone under, I figured I'd reverse engineer a stitching box and provide instructions on how to re-install from the publicly available firmware.

# Stitching box details

The stitching box that I have available is a rebadged Zotac EN1060 Plus i3 box; it appears that Orah also sold an older Zotac box, but I haven't seen those. Basic hardware specifications:
* Intel i3-6100T CPU
* NVidia GTX 1060 Mobile GPUa
* 32gb SATA SSD (M.2 module installed with a 2.5" adapter)
* 8gb DDR4 RAM (installed as a single module on my box, with a second slot available)
* Two ethernet ports:
  * eth0 - Used for communication with the camera
  * eth1 - General network connection - also used to masquerade NAT'd traffic
* Intel Wireless 3165 - configured with hostapd; SSID is 'ORAH4i_00012e70xxxx' (MAC of eth1), password is '0123456789'.  Note that clients connecting via this interface have access to everything on eth1 via NAT - that's a fun security hole!

It runs:
* dhcpd
  * wifi network: 10.224.224.128/25 - 10 client addresses available
  * eth0: 10.223.223.128/25 - .130 to .254 available for clients
* nginx
  * Accepts RTMP stream from the cameras, allows VideoStitch to access (application inputs)
  * Accepts RTMP stream from VideoStitch, makes available via HLS for previewing (application live)
  * Can record any of those streams (individual cameras and stitched camera), not sure if this is possible to enable via UI
  * Proxies web traffic to VS server (below)
* VideoStitch Server (vs_server)
  * Watches for a camera to appear via ZeroConf and configures it
  * Stitches video from the cameras
  * Streams the video to the nginx 'live' application via RTMP for preview via HLS
  * (Optionally) records streams to SD card
  * (Optionally) livestreams to user-provided RTMP endpoint

# Re-installing stitching box from scratch

If you have a stitching box (or _very_ similar hardware) that you want to install from scratch, here's what you need to do!

## Prepare hardware

If the BIOS isn't configured - there are photos of the expected BIOS configuration in the Dropbox/IA link above.

If your SSD already has an OS installed on it, you might need to boot off a live USB drive and wipe it out.

Note that NVMe drives will _not_ work with this installer -- the disk needs to appear as 'sda'.

## Download software

A user uploaded an archive of the Orah support webpage to Dropbox in a [comment on an issue in the stitchEm project](https://github.com/stitchEm/stitchEm/issues/54#issuecomment-620036066). The files are available [on Dropbox](https://github.com/stitchEm/stitchEm/issues/54#issuecomment-620036066), and I've also updated them to the [Internet Archive](https://archive.org/details/orah-4i) for safekeeping.

If you just need to re-install a stitching box, you'll need to download the following files from either Dropbox or IA above:
* Orah OS/Orah_1_2_0/Orah_1.2.0.fw
* Orah OS/Orah_1_2_0/Orah_1.2.0.fw.sign
..but there are other interesting files here - user manuals, support documents, etc - take a look!

In addition, you'll need the following files from this repository:
* boot-files/grub-efi/* - EFI-bootable version of Grub, stolen from the Ubuntu 20.04 live cd
* boot-files/orah-flash-tool/gordon - Extracted from the EFI partition of a working stitching box - this is a combined Linux kernel and rootfs image that is used to install or update the stitching box's OS

## Prepapre a USB stick

You'll need a USB stick that you can wipe out; minimum size is probably 1gb.

* Create a single active (bootable) partition, and format as fat32
* Create the directory tree '/EFI/boot'
* Copy the files:
  * grub-efi files to '/EFI/boot'
  * gordon to '/EFI'
  * Orah-1.2.0.fw* to '/'
* Insert the USB drive into your stitching box
* Power on, and hit F8 to enter the boot menu. Boot off the USB stick.
* You should get a bare grub prompt. Run 'ls', and look for the device that has a 'msdos1' partition.
* Set that device as root. On my box.. `set root=(hd0,msdos1)`
* Run `ls /efi` - you should see the gordon file.
* Specify the kernel to boot: `linux /efi/gordon consoleblank=0`
* Run `boot` to start the boot process

Once the kernel is done initializing, you should see a quick message flash by that says 'Orah firmware found', and then a bunch of stuff will start scrolling by. It may look like it's asking for user input at some points - but it's not.. they are just echo'ing the answers to the script. It writes zeros to the entire length of your drive, so this may take awhile, without any visible progress - just let it run. When it it is done, it will reboot, and the systme should boot into the working Orah OS.  (Note that when it's fully booted it starts an X server that displays nothing until the camera is initialized, at which point it displays video.. so don't be expecting to see much!)

If you run into any issues, feel free to ask.. I have very limited experience with these, but can try to help.

# Enabling SSH access

If you'd like to be able to SSH into the stitching box and play with it, that is also possible. SSH is already enabled, we just don't know the credentials.. so reset 'em.

* Prep a USB stick with a live OS that supports LUKS - I just used an Ubuntu 20.04 live ISO.
* Boot the system from USB, you might need to use safe graphics.
* Get to a shell, and enable SSH (if Ubuntu Live - exit the installer. Once the full desktop starts, ctrl-alt-f2, and log in as ubuntu. Then, 'passwd ubuntu' to set a password, 'apt update ; apt -y install ssh' to install ssh, and note the IP address)
* scp the 'encryption-keys/drive.key' file from this repository to /var/tmp on the stitching box
* SSH to the stitching box, `sudo su -`, and run..
  * `/usr/sbin/cryptsetup luksOpen -d /var/tmp/drive.key /dev/sda2 encroot`
  * `mkdir /mnt/orah ; mount /dev/mapper/encroot /mnt/orah`
  * `chroot /mnt/orah` then `su -` to get a full shell within the stitching box's root partition
  * `passwd root ; passwd videostitch` - to set passwords for each account
  * `vi /etc/ssh/sshd_config` - comment out `PasswordAuthentication no`
  * `vi ~videostitch/.ssh/authorized_keys` - if you want to add an authorized key
  * run 'exit' twice (to get out of 'su -' and then chroot)
  * `umount /mnt/orah ; cryptsetup luksClose encroot`
  * reboot, and allow the system to boot into Orah
* SSH to the system as videostitch, using either the password you set or the private key associated with the public key you added.
* To become root, 'su -', and enter the root password that you set. There isn't sudo on the orah image.

Have fun!
