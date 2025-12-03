#!/usr/bin/env bash
set -euo pipefail

sudo apt-get clean
sudo apt-get autoremove -y
sudo rm -rf /tmp/* /var/tmp/*
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY

# Clear shell history
cat /dev/null > ~/.bash_history || true
history -c || true
