#!/bin/env bash
# Uses bashisms since they are most handy for my script
# Installs arch linux on the selected drive with LUkS
# Setup relies on: systemd-boot, UEFI, LVM and luks, netctl, Xorg, bspwm

# Drive paritions to install to.
#DRIVE="/dev/sde"
clear
lsblk
echo "What is the drive you want to format and install in the form '/dev/sda'"
echo "WARNING: THIS DRIVE WILL BE NUKED"
read -r -p "Drive: " DRIVE

# System timezone.
read -r -p "What is your timezone in the form 'Country/Region'? " TIMEZONE

lscpu
echo "Do you have an Intel or AMD cpu? "
select intelamd in "Intel" "AMD"; do
    case $intelamd in
        Intel) MICROCODE="intel-ucode" ;;
        AMD) MICROCODE="amd-ucode" ;;
        *) echo "Please select 1 or 2" ;;
    esac
    break
done

echo "Turning off that fucking beep...."
rmmod pcspkr

# Setup network connection
#wifi-menu
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
curl "https://www.archlinux.org/mirrorlist/?country=AU&protocol=http&protocol=https&ip_version=4" > /etc/pacman.d/mirrorlist
#Removes initial # from curl-ed file
sed -i 's/^.//' /etc/pacman.d/mirrorlist
pacman -Syy
pacstrap /mnt base base-devel linux linux-firmware iwd git zsh vim openssh lvm2 man-db man-pages texinfo "$MICROCODE"

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "System will now chroot onto /mnt
Please curl <++>02 and run that next
"

#Copy files needed for next part
curl https://raw.githubusercontent.com/WnndGws/warbs/master/02_chrooted.sh > /mnt/02.sh
chmod +x /mnt/02.sh

# arch-chroot
arch-chroot /mnt
