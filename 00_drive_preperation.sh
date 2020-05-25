#!/bin/sh
# Installs arch linux on the selected drive with LUKS
# Setup relies on: systemd-boot, UEFI, LVM and luks, netctl, Xorg, bspwm

echo "Please do the following manually:
1) Run cgdisk 'cgdisk /dev/sdX'
2) Clear all current partitions
3) REBOOT! \n
"

echo "Next do the the following manually:
1) Run cgdisk 'cgdisk /dev/sdX'
2) Create a parition table as such:
Partition   Space   Type
/dev/sda1   512M    EFI System
/dev/sda2   xG      Linux Filesystem
"

echo "curl https://raw.githubusercontent.com/WnndGws/warbs/master/01_base_arch_install.sh
Run 01_base_arch_install.sh"
