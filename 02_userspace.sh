#!/bin/sh
# Creates a bspwm userspace

# Xorg
pacman -S xorg-server xorg-apps gnu-free-fonts polybar systemd-boot-pacman-hook xorg-xinit

# Pikaur
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -fsri

# Pikaur packages
pikaur -S starship trash-cli firefox


