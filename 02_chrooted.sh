#!/bin/env bash
# Installs arch linux on the selected drive with LUkS
# Setup relies on: systemd-boot, UEFI, LVM and luks, netctl, Xorg, bspwm

# Exit if any line errors
set -e

# Source config
. config.ini

# Initial locales
echo "Setting up locale...."
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

# Locale
echo "en_AU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_AU.UTF-8
LC_COLLATE=C" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname

echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Edit mkinitcpio to move 'keyboard to before filesystems, and include encryption
echo "Setting up mkinitcpio...."
sed -i "s/\ keyboard//g" /etc/mkinitcpio.conf
sed -i "s/filesystems/keyboard\ encrypt\ lvm2\ resume\ filesystems/g" /etc/mkinitcpio.conf
mkinitcpio -p linux

# Systemd boot
echo "Setting up Systemd-boot...."
bootctl --path=/boot install

cat > /boot/loader/entries/arch.conf <<EOF
title Arch Linux
linux /vmlinuz-linux
initrd /$MICROCODE.img
initrd /initramfs-linux.img
options cryptdevice=UUID=$(blkid -s UUID -o value "$DRIVE"2):cryptlvm root=/dev/mapper/vg0-root rw
EOF

cat /boot/loader/loader.conf <<EOF
default       arch
timeout       5
console-mode  max
EOF

bootctl --path=/boot update

clear
echo "Set root password...."
passwd

# Add user
clear
echo "Adding user...."
# Note no need to add user to the audio or video groups as in the past, as udev now handles permissions for us.
useradd --create-home --gid users --shell /bin/zsh "$USER_NAME"
# Adding to wheel after creating as it was not adding propperly for some reason
usermod -a -G  wheel "$USER_NAME"
echo "Passwd for $USER_NAME...."
passwd $USER_NAME

echo "Adding %wheel to sudoers file...."
sed -i 's/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Setup zsh to use XDG
cat > /etc/zsh/zshenv <<EOF
ZDOTDIR=/home/$USER_NAME/.config/zsh
EOF

curl https://raw.githubusercontent.com/WnndGws/warbs/master/03_userspace.sh >> /home/"$USER_NAME"/03.sh
chmod +x /home/"$USER_NAME"/03.sh
cp config.ini /home/"$USER_NAME"/config.ini

clear
echo "Please reboot, and run $HOME/03.sh for Userspace install"
