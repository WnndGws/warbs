#!/bin/sh
# Installs arch linux on the selected drive with LUkS
# Setup relies on: systemd-boot, UEFI, LVM and luks, netctl, Xorg, bspwm

# Get user input
read -p "What is the drive you want arch installed on (in the form /dev/sda)?: " drive

echo "Turning off that fucking beep...."
rmmod pcspkr

# Setup network connection
#wifi-menu
echo "Setting up network...."
sleep 1
timedatectl set-ntp true
timedatectl set-timezone Australia/Perth

# Prepare encrypted container
echo "Preparing luks...."
modprobe dm-crypt
cryptsetup luksFormat --type luks2 --cipher aes-xts-plain64 --key-size 512 $drive\2
cryptsetup open $drive\2 cryptlvm

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
mkfs.fat -F32 $drive\1
mkdir /mnt/boot
mount $drive\1 /mnt/boot

# Create swap
mkswap /dev/mapper/vg0-swap
swapon /dev/mapper/vg0-swap

# Pacstrap
echo "Initialising pacstrap...."
curl "https://www.archlinux.org/mirrorlist/?country=AU&protocol=http&protocol=https&ip_version=4" > /etc/pacman.d/mirrorlist
pacman -Syy
pacstrap /mnt base base-devel linux linux-firmware netctl git zsh vim dialog wpa_supplicant dhcpcd openssh lvm2

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "System will now chroot onto /mnt
Please curl <++>02 and run that next
"

# arch-chroot
arch-chroot /mnt
