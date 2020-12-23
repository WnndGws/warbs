#!/bin/env bash
## Using zsh since that us my user shell, but also so we can use bash-isms

# Exit script if anything fails
set -e

# Source config
. config.ini

# Cleanup old file
sudo /bin/rm -rf /02.sh

echo "Turning off that fucking beep...."
sudo rmmod pcspkr

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
# TODO: Check that yes works, since know ipv4 works
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

# Required for 32bit vulkan support
echo "Adding multilib to pacman.conf for 32 bit support"
LINESTART=$(grep -Fnr "[multilib]" /etc/pacman.conf | cut -d : -f1)
LINEEND=$((LINESTART+1))
sudo sed -i "${LINESTART},${LINEEND} s/^#//" /etc/pacman.conf
sleep 5
sudo pacman -Syyuu

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
sudo timedatectl set-ntp true

# Need a sleep for the internet to sort itself out
sleep 5

echo "installing pikaur...."
git clone https://aur.archlinux.org/pikaur.git
cd pikaur || exit
makepkg --force --syncdeps --rmdeps --install
cd .. || exit
rm -rf pikaur

echo "Updating system before continuing...."
sudo pacman -Syyuu
sudo pacman -S xorg-server xorg-apps gnu-free-fonts "$VIDEO_DRIVER" xorg-xinit mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader "$VIDEO_DRIVER_2" "$VIDEO_DRIVER_3" mesa-vdpau

# Step 3
# Install all utilities I use frequently including my Window Manager
pikaur -S alacritty bspwm sxhkd firefox mpv youtube-dl newsboat nerd-fonts-cascadia-code fasd xdo \
rofi ripgrep fd bat neofetch exa entr feh neovim lemonbar-xft-git git-crypt starship stow trash-cli \
pulseaudio-alsa pulsemixer pamixer unclutter-xfixes-git xclip zathura zathura-pdf-mupdf dash dashbinsh \
fzf xorg-xmodmap zsh-autosuggestions find-the-command zsh-syntax-highlighting tealdeer zsh-history-substring-search python python-pynvim zsh-you-should-use

# Need to create a pacman database for find-the-command to work
sudo pacman -Fy
sudo systemctl enable --now pacman-files.timer

# Step 4
# Pull and stow dotfiles
# Set ZSH to use XDG base
#sudo bash -c 'cat > /etc/zsh/zshenv <<EOF
#ZDOTDIR=/home/$USER_NAME/.config/zsh
#EOF'

mkdir ~/git && cd ~/git
git clone https://github.com/wnndgws/scripts.git
git clone https://github.com/wnndgws/dotfiles.git
git clone https://github.com/wnndgws/wyman.git
cd ~/git/dotfiles
for i in */; do
    stow --restow --target="$HOME" "$i"
done

zsh
mkdir "$XDG_CACHE_HOME"/zsh

## TODO, git-crypt unlock

# Step 5
# SSH and GPG
#mkdir "$XDG_CONFIG_HOME"/gnupg
printf 'We are past the automatic stage, the rest has to be done manually.

We will set up a gpg key
The primary key should be for signing and certification only. The suggested usage of GPG is to create a subkey for encryption. This subkey is a separate key that, for all intents and purposes, is signed by your primary key and transmitted at the same time. This practice allows you to revoke the encryption subkey on its own, such as if it becomes compromised, while keeping your primary key valid.
To create a new key run:
* `gpg --full-generate-key --expert`
* Select RSA (Set your own capabilities) and check it can sign and certify only

To import a key run:
* `gpg import key.asc`

The rest of the steps are the same.

Next need to generate subkeys. One for authentication only to use with ssh, and one for encryption only
* `gpg --expert --edit-key <KEY-ID>`
* addkey, select RSA (Set your own capabilities), and follow promts to make these two subkeys

To unlock the authentication key for the whole session run
* `gpg --with-keygrip -k`
* `/usr/lib/gnupg/gpg-preset-passphrase --preset <KEYGRIP>`
* `echo <KEYGRIP> >> $XDG_CONFIG_HOME/gnupg/sshcontrol`
    * NB, MUST HAVE MAIN EY AND SUBEY IN SSHCONTROL FILE

The rest should be handled correctly by .zshenv file
'

# Step 6
# Set up firefox
