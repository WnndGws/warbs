#!/bin/sh
# Creates a bspwm userspace

groupadd mediamgmt
useradd --create-home -G wheel -G audio -G video -G mediamgmt --shell /bin/zsh wynand
passwd wynand

# Xorg
pacman -S xorg-server xorg-apps gnu-free-fonts polybar systemd-boot-pacman-hook xorg-xinit

# Pikaur
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -fsri

# Pikaur packages
pikaur -S starship trash-cli firefox


