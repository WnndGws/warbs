#!/bin/env bash
# Installs arch linux on the selected drive with LUKS
# Setup relies on: systemd-boot, UEFI, LVM and luks, netctl, Xorg, bspwm

cat <<EOF
Please do the following manually:
1) Run cgdisk 'cgdisk /dev/sdX'
2) Clear all current partitions
3) REBOOT!

Next do the the following manually:
1) Run cgdisk 'cgdisk /dev/sdX'
2) Create a partition table as such:
Partition   Space   Type
/dev/sda1   512M    EFI System
/dev/sda2   xG      Linux Filesystem
EOF

lscpu
lspci | grep -i 'vga\|3d\|2d'

cat <<EOF
UPDATE THE CONFIG FILE
EOF

curl https://raw.githubusercontent.com/WnndGws/warbs/master/01_base.sh > 01.sh
chmod +x 01.sh

curl https://raw.githubusercontent.com/WnndGws/warbs/master/config.ini > config.ini

echo "Please run 01.sh"
