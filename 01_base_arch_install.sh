#!/bin/sh
# Installs arch linux on the selected drive with LUkS
# Setup relies on: systemd-boot, UEFI, LVM and luks, netctl, Xorg, bspwm

# Get user input
read -p "What is the drive you want arch installed on (in the form /dev/sda)?: " drive
read -p "What is the hostname?: " hostname

# Setup network connection
wifi-menu
timedatectl set-ntp true
timedatectl set-timezone Australia/Perth

# Prepare encrypted container
cryptsetup luksFormat --type luks2 --cipher aes-xts-plain64 --key-size 512 $drive\2
cryptsetup open $drive\2 cryptlvm

# Create physical volume
pvcreate /dev/mapper/cryptlvm

# Create volume group
vgcreate vg0 /dev/mapper/cryptlvm

# Create logical volumes
lvcreate -L 24G vg0 -n swap
lvcreate -l 100%FREE vg0 -n root

# Create /
mkfs.ext4 /dev/vg0/root
mount /dev/vg0/root /mnt

# Create /boot
mkfs.fat -F32 $drive\1
mkdir /mnt/boot
mount $drive\1 /mnt/boot

# Create swap
mkswap /dev/vg0/swap
swapon /dev/vg0/swap

# Pacstrap
pacstrap /mnt base base-devel linux linux-firmware netctl bspwm sxhkd git zsh alacritty vim dialog wpa_supplicant dhcpcd openssh

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# arch-chroot
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Australia/Perth /etc/localtime
hwclock --systohc

# Locale
echo "en_AU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_AU.UTF-8
LC_COLLATE=C" > /etc/locale.conf

echo "$hostname" > /etc/hostname

echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts

# Systemd boot
bootctl --path=/boot install

echo "title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value $drive\3)=cryptlvm root=/dev/vg0/root rw" > /boot/loader/entries/arch.conf

echo "default       arch
timeout       5
console-mode  max" > /boot/loader/loader.conf

bootctl --path=/boot update

echo "uncomment this line in /etc/sudoers:
%wheel ALL=(ALL) ALL
"
echo "Please reboot, and run 02_userspace.sh"
