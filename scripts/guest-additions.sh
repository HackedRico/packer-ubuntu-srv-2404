#!/usr/bin/env bash
set -euo pipefail

sudo mkdir -p /mnt/vbox
if sudo mount -o loop /home/vagrant/VBoxGuestAdditions.iso /mnt/vbox; then
  :
elif sudo mount -o loop /root/VBoxGuestAdditions.iso /mnt/vbox; then
  :
else
  echo "Guest Additions ISO not found" >&2
  exit 1
fi

sudo sh /mnt/vbox/VBoxLinuxAdditions.run || true
sudo umount /mnt/vbox
