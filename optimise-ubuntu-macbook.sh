#!/bin/bash
# optimize-ubuntu-macbook.sh
# Reproduces the optimizations applied on a MacBook Air 2017 (Ubuntu 22.04+ with XFCE)
# Author: Based on real-world setup
# License: MIT

set -e  # Stop on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Ubuntu + XFCE Optimizer for MacBook Air ===${NC}"
echo "This script will apply the exact optimizations used on a MacBook Air 2017 (8GB RAM)."
echo "It is safe to run multiple times (idempotent)."
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Do not run as root. Run as normal user (sudo will be asked when needed).${NC}"
   exit 1
fi

# Detect OS
if ! grep -qi "ubuntu" /etc/os-release; then
    echo -e "${YELLOW}Warning: This script was written for Ubuntu. Other distros may work but are untested.${NC}"
fi

# 1. Install and configure TLP (power management)
echo -e "\n${GREEN}[1/4] Installing TLP (advanced power management)${NC}"
if ! command -v tlp &> /dev/null; then
    sudo apt update
    sudo apt install -y tlp tlp-rdw
    sudo systemctl enable tlp
    sudo systemctl start tlp
    echo -e "${GREEN}TLP installed and started.${NC}"
else
    echo "TLP already installed."
fi

# 2. Configure zRAM (compressed RAM as swap)
echo -e "\n${GREEN}[2/4] Ensuring zRAM is active${NC}"
# On Ubuntu 22.04+, systemd-zram-generator is the modern method
if ! dpkg -l | grep -q systemd-zram-generator; then
    sudo apt install -y systemd-zram-generator
fi

# Create default config if not exists
ZRAM_CONF="/etc/systemd/zram-generator.conf"
if [ ! -f "$ZRAM_CONF" ]; then
    echo "Creating $ZRAM_CONF with 50% of RAM as compressed swap..."
    sudo tee "$ZRAM_CONF" > /dev/null <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = lzo-rle
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-zram-setup@zram0.service
    echo -e "${GREEN}zRAM configured.${NC}"
else
    echo "zRAM config already present."
fi

# Show current zRAM status
echo "Current zRAM:"
sudo zramctl

# 3. Set CPU governor to schedutil (modern, balanced)
echo -e "\n${GREEN}[3/4] Setting CPU governor to 'schedutil'${NC}"
GOVERNOR="schedutil"
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ -f "$cpu" ]; then
        echo "$GOVERNOR" | sudo tee "$cpu" > /dev/null
    fi
done
# Make persistent (via udev rule)
UDEV_RULE="/etc/udev/rules.d/99-cpu-governor.rules"
if [ ! -f "$UDEV_RULE" ]; then
    echo "ACTION==\"add\", SUBSYSTEM==\"cpu\", ATTR{online}==\"1\", TEST==\"cpufreq/scaling_governor\", ATTR{cpufreq/scaling_governor}=\"$GOVERNOR\"" | sudo tee "$UDEV_RULE" > /dev/null
    echo -e "${GREEN}CPU governor set to $GOVERNOR persistently.${NC}"
else
    echo "CPU governor rule already exists."
fi

# 4. Optional: lower swappiness (user can uncomment)
echo -e "\n${GREEN}[4/4] Optional tweaks (commented out by default)${NC}"
echo "The following optimizations were considered but not applied in the original setup."
echo "To enable them, edit this script and uncomment the lines below."
cat << EOF
# Uncomment these lines if you want:
# --------------------------------
# # Lower swappiness to 10 (favors RAM)
# echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
# sudo sysctl -p
#
# # Disable XFCE compositing (saves GPU/CPU)
# xfconf-query -c xfwm4 -p /general/use_compositing -s false
#
# # Move /tmp and /var/tmp to RAM (reduces SSD writes)
# echo "tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0" | sudo tee -a /etc/fstab
# echo "tmpfs /var/tmp tmpfs defaults,noatime,mode=1777 0 0" | sudo tee -a /etc/fstab
# sudo mount -a
# --------------------------------
EOF

echo -e "\n${GREEN}=== Optimisation complete ===${NC}"
echo "Your system now has:"
echo "  - TLP active (power management)"
echo "  - zRAM enabled ($(sudo zramctl --noheadings -o DISKSIZE | head -1) compressed swap)"
echo "  - CPU governor set to schedutil"
echo ""
echo "To verify battery/power: run 'sudo tlp-stat -b' and 'powertop' (install if needed)."
B
B
B
B
echo "Reboot is not required but recommended."
