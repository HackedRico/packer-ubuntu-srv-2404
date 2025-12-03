#!/usr/bin/env bash
set -euo pipefail

SSH_DIR="/home/vagrant/.ssh"

# Install Vagrant insecure key
install -d -m 700 "${SSH_DIR}"
curl -fsSL https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub -o "${SSH_DIR}/authorized_keys"
chmod 600 "${SSH_DIR}/authorized_keys"
sudo chown -R vagrant:vagrant "${SSH_DIR}"

# Ensure SSH is configured for password and key auth
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh || sudo systemctl restart sshd
