#!/usr/bin/env bash
set -eux

echo "==== Updating system ===="
apt-get update -y
apt-get upgrade -y

echo "==== Creating vagrant user ===="
if ! id -u vagrant >/dev/null 2>&1; then
    useradd -m -s /bin/bash vagrant
fi

echo "vagrant:vagrant" | chpasswd
usermod -aG sudo vagrant

echo "==== Adding passwordless sudo ===="
echo "vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
chmod 440 /etc/sudoers.d/vagrant

echo "==== Installing SSH key for vagrant ===="
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
curl -fsSL https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub \
    > /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

echo "==== Installing VirtualBox Guest Additions dependencies ===="
apt-get install -y build-essential dkms linux-headers-$(uname -r) || true

# Only run if VBox CD is mounted
if [ -e /dev/cdrom ]; then
    echo "==== Installing VBox Guest Additions (if ISO exists) ===="
    mount /dev/cdrom /mnt || true
    if [ -f /mnt/VBoxLinuxAdditions.run ]; then
        bash /mnt/VBoxLinuxAdditions.run || true
    fi
    umount /mnt || true
fi

echo "==== Cleanup APT + logs ===="
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "==== Cleaning temp files ===="
rm -rf /tmp/* /var/tmp/*
truncate -s 0 /var/log/*.log || true

echo "==== Zeroing disk to reduce box size ===="
dd if=/dev/zero of=/EMPTY bs=1M || true
rm -f /EMPTY

echo "==== Done. Shutting down for packaging. ===="
shutdown -h now
