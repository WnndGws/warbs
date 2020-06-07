#!/bin/env zsh
## Using zsh since that is my user shell, but also so we can use bash-isms

echo "Turning off that fucking beep...."
rmmod pcspkr

read -p "What USER are you logged in as? " USER_NAME

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
pikaur -S alacritty bspwm sxhkd firefox mpv youtube-dl newsboat nerd-fonts-cascadia-code fasd xdo \
rofi ripgrep fd bat neofetch exa entr feh neovim lemonbar-xft-git git-crypt starship stow trash-cli \
pulseaudio-alsa pulsemixer pamixer unclutter-xfixes-git xclip zathura zathura-pdf-mupdf dash dashbinsh \
fzf xorg-xmodmap zsh-autosuggestions find-the-command zsh-syntax-highlighting tealdeer zsh-history-substring-search

# Need to create a pacman database for find-the-command to work
sudo pacman -Fy
sudo systemct enable --now pacman-files.timer

# Step 4
# Pull and stow dotfiles
# Set ZSH to use XDG base
sudo bash -c 'cat > /etc/zsh/zshenv <<EOF
ZDOTDIR=/home/$USER_NAME/.config/zsh
EOF'

mkdir ~/git && cd ~/git
git clone https://github.com/wnndgws/scripts.git
git clone https://github.com/wnndgws/dotfiles.git
cd ~/git/dotfiles
for i in $(ls); do
    stow --restow --target=$HOME $i
done

mkdir $XDG_DATA_HOME/vim
mkdir $XDG_DATA_HOME/vim/{undo,swap,backup,view}
mkdir $XDG_CACHE_HOME/zsh

## TODO, move away from polybar to lemonbar
## TODO, git-crypt unlock

# Step 5
# SSH and GPG
mkdir $XDG_CONFIG_HOME/gnupg
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
