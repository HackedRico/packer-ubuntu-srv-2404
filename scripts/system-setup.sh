#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Keep the clock in sync so apt trusts repository metadata
sudo timedatectl set-ntp true || true
sudo systemctl restart systemd-timesyncd || true
if command -v hwclock >/dev/null 2>&1; then
  sudo hwclock --hctosys || true
fi
sleep 5

# Work around mirror metadata that is newer than the local clock
echo 'Acquire::Check-Valid-Until "false";' | sudo tee /etc/apt/apt.conf.d/99-ignore-valid-until >/dev/null

sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y \
    build-essential \
    "linux-headers-$(uname -r)" \
    realmd \
    libnss-sss \
    libpam-sss \
    sssd \
    sssd-tools \
    adcli \
    samba-common-bin \
    oddjob \
    oddjob-mkhomedir \
    packagekit \
    python3-pexpect \
    krb5-user

sudo apt-get autoremove -y
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo rm -f /etc/apt/apt.conf.d/99-ignore-valid-until

sudo touch /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
