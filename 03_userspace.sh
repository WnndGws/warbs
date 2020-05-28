#!/bin/env zsh
## Using zsh since that us my user shell, but also so we can use bash-isms

lspci | grep VGA
echo "Do you have an Intel, NVidia, AMD, or generic GPU? "
select driver in "Intel" "NVidia" "AMD" "Generic"; do
    case $driver in
        Intel ) VIDEO_DRIVER="xf86-video-i915" ;;
        NVidia ) VIDEO_DRIVER="xf86-video-nouveau" ;;
        AMD ) VIDEO_DRIVER="xf86-video-amdgpu" ;;
        Generic ) VIDEO_DRIVER="xf86-video-vesa" ;;
        * ) echo "Please select 1-4" ;;
    esac
done

# Remove 02.sh used for install
echo "Removing 02.sh from root directory...."
sudo rm /02.sh

# Step 1
# Wifi
echo "Setting up WiFi...."
echo "Many of these files are readonly unless super user"
sudo su -

ip link set wlan0 up
systemctl enable --now systemd-networkd.service
systemctl enable --now systemd-resolved.service
systemctl enable --now iwd.service

echo "Creating iwd's main.conf...."
cat > /etc/iwd/main.conf <<EOF
[Scan]
# Disable periodic scanning for new networks
DisablePeriodScan=true

[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF

cat > /etc/systemd/network/wifi.network <<EOF
[Match]
Name=wlan*

[Network]
# TODO: Check that yes works, since know 'ipv4' works
DHCP=yes
IPv6PrivacyExtensions=true
EOF

# Links the systemd-resolved stub to resolv.conf incase theres any programs that still need to check resolv.conf
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=1.1.1.1 9.9.9.9
Domains=~.
FallbackDNS=
DNSOverTLS=yes
EOF

#exit su
exit

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

# Step 2
# Video drivers + xorg
echo "Updating system before continuing...."
pacman -Syyu
clear
pacman -S xorg-server xorg-apps gnu-free-fonts "$VIDEO_DRIVER" xorg-xinit

# Step 3
# SSH and GPG

# Step 4
# Install all utilities

# Step 5
# Pull and stow dotfiles

# Step 6
# Set up firefox
