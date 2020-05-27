#!/bin/sh
# Installs arch linux on the selected drive with LUkS
# Setup relies on: systemd-boot, UEFI, LVM and luks, netctl, Xorg, bspwm

# Drive paritions to install to.
DRIVE="/dev/sde"

# Hostname of installed machine
HOSTNAME="desk-ARCH"

# Main user to create (by default, added to wheel group, and others).
USER_NAME="wynand"

# System timezone.
TIMEZONE="Australia/Perth"

# Choose your video driver
# Run `lspci | grep VGA` for video driver info
# For Intel
#VIDEO_DRIVER="i915"
# For nVidia
#VIDEO_DRIVER="nouveau"
# For ATI
#VIDEO_DRIVER="amdgpu"
# For generic stuff
#VIDEO_DRIVER="vesa"

# Choose and uncomment you CPU microcode
# Run `lscpu` for more info
# For Intel
#MICROCODE="intel-ucode"
# For AMD
#MICROCODE="amd-ucode"

echo "Did you make EXTRA sure the the variables in 01.sh are correct?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
        *) echo "Select 1 or 2...."
    esac
done

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
options cryptdevice=UUID=$(blkid -s UUID -o value "$DRIVE"2):cryptlvm root=/dev/mapper/vg0-root quiet rw
EOF

cat /boot/loader/loader.conf <<EOF
default       arch
timeout       5
console-mode  max
EOF

bootctl --path=/boot update

echo "Set root password...."
passwd

# Add user
echo "Adding user...."
groupadd mediamgmt
# Note no need to add user to the audio or video groups as in the past, as udev now handles permissions for us.
useradd --create-home --gid users --groups wheel --groups mediamgmt --shell /bin/zsh $USER_NAME
echo "Passwd for $USER_NAME...."
passwd $USER_NAME

echo "Adding %wheel to sudoers file...."
sed -i 's/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/' /etc/sudoers

curl https://raw.githubusercontent.com/WnndGws/warbs/master/03_userspace.sh >> /home/"$USER_NAME"/03.sh
chmod +x /home/"$USER_NAME"/03.sh

clear
echo "Please reboot, and run $HOME/03.sh for Userspace install"
