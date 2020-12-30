# warbs
WnndGws's Auto Ricing Bootstrap Script

# Motivation
I am writing this script because I do something often enough (once every 6-8 months) where I want/need to reinstall Arch Linux on one of my computers. I am just following the same steps over and over, so I am attempting to automate this process

# The scripts
The scripts are intended to work only for me, tweaking can be done, but for now I have hardcoded everything

The scripts are intented to be run in order as each leaves the system in a state for the next one

# Usage
1) Live boot arch linux on new computer
2) `lsblk` to find the drive you want to nuke
3) `wifi-menu` if using wifi to connect to network (warbs uses iwd, but this is an easier alternative in the live environment)
4) `pacman -Syy`
5) `curl https://raw.githubusercontent.com/wnndgws/warbs/master/00_init.sh > 00.sh && chmod +x 00.sh`
6) READ EACH SCRIPT AT EACH STEP
7) `./00.sh` and follow the prompts
