packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

#####################################################################################
# variables
#####################################################################################

# VM specification
variable "vm_name" {
  type        = string
  description = "This is the name of the OVF file for the new VM"
  default     = "vagrant-ubuntu2404"
}

variable "guest_os_type" {
  type        = string
  description = "The guest OS being installed"
  default     = "Ubuntu_64"
}

variable "ssh_timeout" {
  type        = string
  description = "The time to wait for SSH to become available"
  default     = "10000s"
}

variable "shutdown_command" {
  type        = string
  description = "Command to shutdown VM when provisions are created"
  default     = "echo 'vagrant' | sudo -S shutdown -P now"
}

variable "boot_wait" {
  type        = string
  description = "Time to wait after booting the initial VM"
  default     = "6s"
}
variable "communicator" {
  type        = string
  description = "The type of commications VM would use"
  default     = "ssh"
}

# Hardware Configurations
variable "disk_size" {
  type        = number
  description = "The size, in megabytes, of the hard drive to create for the VM"
  default     = "40000"
}

variable "cpus" {
  type        = number
  description = "The number of cpus built for VM"
  default     = "2"
}

variable "memory" {
  type        = number
  description = "The amount of memory built for VM in megabytes"
  default     = "2048"
}

variable "gfx_vram_size" {
  type        = number
  description = "The VRAM size to be used"
  default     = "32"
}

# Network Configuration 
variable "nic_type" {
  type        = string
  description = "The type of network interface card VM uses"
  default     = "82540EM"
}
# HTTP Directory Configuration 
variable "http_directory" {
  type        = string
  description = "Directory where configuration is located"
  default     = "http"
}

# ISO Configuration
variable "iso_url" {
  type        = string
  description = "URL link to download Iso file"
  default     = "https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso"
}

variable "iso_checksum" {
  type        = string
  description = "Iso download validation"
  default     = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
}

# Credentials 
variable "ssh_username" {
  type        = string
  description = "SSH connection username"
  default     = "vagrant"
  sensitive   = true
}

variable "ssh_password" {
  type        = string
  description = "SSH connection password"
  default     = "vagrant"
  sensitive   = true
}

# SSH Rules
variable "ssh_handshake_attempts" {
  type        = number 
  description = "Number of attempts to make an ssh connection"
  default     = "10"
}

#####################################################################################
# Sources
#####################################################################################

source "virtualbox-iso" "UbuntuServer" {
  boot_wait              = var.boot_wait
  communicator           = var.communicator
  cpus                   = var.cpus
  disk_size              = var.disk_size
  gfx_vram_size          = var.gfx_vram_size
  guest_os_type          = var.guest_os_type
  http_directory         = var.http_directory
  iso_url                = var.iso_url
  iso_checksum           = var.iso_checksum
  nic_type               = var.nic_type
  memory                 = var.memory
  ssh_username           = var.ssh_username
  ssh_password           = var.ssh_password
  ssh_timeout            = var.ssh_timeout
  ssh_handshake_attempts = var.ssh_handshake_attempts
  shutdown_command       = var.shutdown_command
  vm_name                = var.vm_name
  format                 = "ovf"

  cd_files = [
    "./http/meta-data",
    "./http/user-data"
  ]

  cd_label = "cidata"

  boot_command = [
        "<esc><wait>",
        "c<wait>",
        "set gfxpayload=keep<enter>",
        "linux /casper/vmlinuz autoinstall ds=nocloud;s=/dev/sr1/ ---<enter>",
        "initrd /casper/initrd<enter>",
        "boot<enter>"
    ]

  # Default networking uses VirtualBox NAT so the VM can reach the internet.
  # Uncomment the block below and adjust adapter names if you need bridged/host-only networking.
  # vboxmanage = [
  #   ["modifyvm", "{{.Name}}", "--nic1", "bridged"],
  #   ["modifyvm", "{{.Name}}", "--bridgeadapter1", "en0"]
  # ]
}

#####################################################################################
# Build Source
#####################################################################################

build {
  sources = ["source.virtualbox-iso.UbuntuServer"]

  # Provision via helper scripts
  provisioner "shell" {
    scripts = [
      "scripts/system-setup.sh",
      "scripts/guest-additions.sh",
      "scripts/vagrant-ssh.sh",
      "scripts/cleanup.sh"
    ]
  }

  # Create Vagrant box
  post-processor "vagrant" {
    output = "ubuntu-24.04-vagrant.box"
    compression_level = 9
  }
}
