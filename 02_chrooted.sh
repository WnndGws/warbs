#!/bin/sh
# Installs arch linux on the selected drive with LUkS
# Setup relies on: systemd-boot, UEFI, LVM and luks, netctl, Xorg, bspwm

# Get user input
read -p "What is the hostname?: " hostname
read -p "What is the username?: " username

# Initial locales
echo "Setting up locale...."
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

# Edit mkinitcpio to move 'keyboard to bfore filesystems, and include encryption
echo "Setting up mkinitcpio...."
sed -i 's/\ keyboard//g' /etc/mkinitcpio.conf
sed -i 's/filesystems/keyboard\ encrypt\ lvm2\ resume\ filesystems/g' /etc/mkinitcpio.conf
mkinitcpio -p linux

# Systemd boot
echo "Setting up Systemd-boot...."
bootctl --path=/boot install

echo "title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options cryptdevice=UUID=$(blkid -s UUID -o value $drive\2):cryptlvm root=/dev/mapper/vg0-root quiet rw" > /boot/loader/entries/arch.conf

echo "default       arch
timeout       5
console-mode  max" > /boot/loader/loader.conf

bootctl --path=/boot update

echo "Set root password...."
passwd

# Add user
echo "Adding user...."
groupadd mediamgmt
useradd --create-home -G wheel -G audio -G video -G mediamgmt --shell /bin/zsh $username
passwd $username

echo "uncomment this line in /etc/sudoers:
%wheel ALL=(ALL) ALL
"
echo "Please reboot, and run 03_userspace.sh
<++>03_userspace"
