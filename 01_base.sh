#!/bin/env bash
# Uses bashisms since they are most handy for my script
# Installs arch linux on the selected drive with LUkS
# Setup relies on: systemd-boot, UEFI, LVM and luks, netctl, Xorg, bspwm

# Exit if any line errors
set -e

# Source config file
. config.ini

echo "Turning off that fucking beep...."
rmmod pcspkr

# Setup network connection
echo "Setting up network...."
sleep 1
timedatectl set-ntp true
timedatectl set-timezone "$TIMEZONE"

# Prepare encrypted container
echo "Preparing luks...."
modprobe dm-crypt
cryptsetup luksFormat --type luks2 --cipher aes-xts-plain64 --key-size 512 "$DRIVE"2
echo "Decrypting drive so we can use it...."
cryptsetup open "$DRIVE"2 cryptlvm

# Create physical volume
pvcreate /dev/mapper/cryptlvm

# Create volume group
vgcreate vg0 /dev/mapper/cryptlvm

# Create logical volumes
lvcreate -L24G vg0 -n swap
lvcreate -l 100%FREE vg0 -n root

# Create /
echo "Mounting drives...."
mkfs.ext4 /dev/mapper/vg0-root
mount /dev/mapper/vg0-root /mnt

# Create /boot
mkfs.fat -F32 "$DRIVE"1
mkdir /mnt/boot
mount "$DRIVE"1 /mnt/boot

# Create swap
mkswap /dev/mapper/vg0-swap
swapon /dev/mapper/vg0-swap

# Pacstrap
echo "Initialising pacstrap...."
curl "https://archlinux.org/mirrorlist/?country=AU&protocol=http&protocol=https&ip_version=4" > /etc/pacman.d/mirrorlist
#Removes initial # from curl-ed file
sed -i 's/^.//' /etc/pacman.d/mirrorlist
pacman -Sy
pacstrap /mnt base base-devel linux linux-firmware iwd git zsh neovim openssh lvm2 man-db man-pages texinfo "$MICROCODE"

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "System will now chroot onto /mnt
Please curl <++>02 and run that next
"

#Copy files needed for next part
curl https://raw.githubusercontent.com/WnndGws/warbs/master/02_chrooted.sh > /mnt/02.sh
chmod +x /mnt/02.sh
cp config.ini /mnt/config.ini

# arch-chroot
arch-chroot /mnt
