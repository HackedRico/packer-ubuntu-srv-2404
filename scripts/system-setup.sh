#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y build-essential dkms "linux-headers-$(uname -r)" wget curl
