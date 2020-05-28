#!/bin/env zsh
## Using zsh since that us my user shell, but also so we can use bash-isms

echo "Turning off that fucking beep...."
rmmod pcspkr

lspci | grep -i 'vga\|3d\|2d'
echo "Do you have an Intel, NVidia, AMD, or generic GPU? "
select driver in "Intel" "NVidia" "AMD" "Generic"; do
    case $driver in
        Intel ) VIDEO_DRIVER="xf86-video-i915" ;;
        NVidia ) VIDEO_DRIVER="xf86-video-nouveau" ;;
        AMD ) VIDEO_DRIVER="xf86-video-amdgpu" ;;
        Generic ) VIDEO_DRIVER="xf86-video-vesa" ;;
        * ) echo "Please select 1-4" ;;
    esac
    break
done

# Remove 02.sh used for install
echo "Removing 02.sh from root directory...."
sudo rm /02.sh

# Step 1
# Wifi
echo "Setting up WiFi...."
echo "Many of these files are readonly unless super user"

sudo ip link set wlan0 up
sudo systemctl enable --now systemd-networkd.service
sudo systemctl enable --now systemd-resolved.service
sudo systemctl enable --now iwd.service

echo "Creating iwd's main.conf...."
sudo bash -c 'cat > /etc/iwd/main.conf <<EOF
[Scan]
# Disable periodic scanning for new networks
DisablePeriodScan=true

[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF'

sudo bash -c 'cat > /etc/systemd/network/wifi.network <<EOF
[Match]
Name=wlan*

[Network]
# TODO: Check that yes works, since know 'ipv4' works
DHCP=yes
IPv6PrivacyExtensions=true
EOF'

# Links the systemd-resolved stub to resolv.conf incase theres any programs that still need to check resolv.conf
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

sudo bash -c 'cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=1.1.1.1 9.9.9.9
Domains=~.
FallbackDNS=
DNSOverTLS=yes
EOF'

iwctl station wlan0 scan
iwctl station wlan0 get-networks
read -p "What <SSID> would you like to connect to?" SSID
iwctl station wlan0 connect "$SSID"

echo "If you would like to set a static IP address on the machine do the following:
Edit /var/lib/iwd/<SSID>.psk
> [IPv4]
> ip=192.168.1.100
> netmask=255.255.255.0
> gateway=192.168.1.1
> broadcast=192.168.1.20
"

sudo systemctl restart systemd-networkd.service
sudo systemctl restart systemd-resolved.service
sudo systemctl restart iwd.service

# Step 2
# Video drivers + xorg
echo "Updating system before continuing...."
sudo pacman -Syyu
clear
sudo pacman -S xorg-server xorg-apps gnu-free-fonts "$VIDEO_DRIVER" xorg-xinit

# Enable ntp
echo 'enabling NTP....'
sudo bash -c 'cat > /etc/systemd/timesyncd.conf <<EOF
[Time]
NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOF'
sudo systemctl enable --now systemd-timesyncd.service
sudo timedatectl set-ntp=true

echo "installing pikaur...."
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg --force --syncdeps --rmdeps --install
cd ..
rm -rf pikaur

# Step 3
# Install all utilities I use frequently including my Window Manager
pikaur -S alacritty bspwm sxhkd firefox mpv youtube-dl newsboat nerd-fonts-cascadia-code \
rofi ripgrep fd bat neofetch exa entr feh neovim lemonbar-xft-git \
pulseaudio-alsa pulsemixer pamixer unclutter-xfixes-git xclip zathura zathura-pdf-mupdf \
fzf xmodmap zsh-autosuggestions find-the-command zsh-syntax-highlighting tealdeer zsh-search-history-substring

# Step 4
# SSH and GPG

# Step 5
# Pull and stow dotfiles

# Step 6
# Set up firefox
