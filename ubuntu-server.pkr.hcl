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
# Variables
#####################################################################################

# VM configuration

variable "vm_name" {
  type        = string
  description = "Name of the OVF file for the new VM"
  default     = "vagrant-ubuntu2404"
}

variable "guest_os_type" {
  type        = string
  description = "The guest OS being installed"
  default     = "Ubuntu_64"
}

variable "ssh_timeout" {
  type        = string
  description = "Time to wait for SSH to become available"
  default     = "10000s"
}

variable "shutdown_command" {
  type        = string
  description = "Command to shutdown VM after provisioning"
  default     = "echo 'vagrant' | sudo -S shutdown -P now"
}

variable "boot_wait" {
  type        = string
  description = "Time to wait after booting the initial VM"
  default     = "6s"
}

variable "communicator" {
  type        = string
  description = "Communication type the VM should use"
  default     = "ssh"
}

# Hardware configuration

variable "disk_size" {
  type        = number
  description = "Size in megabytes of the VM hard drive"
  default     = 40000
}

variable "cpus" {
  type        = number
  description = "Number of CPUs for the VM"
  default     = 2
}

variable "memory" {
  type        = number
  description = "Amount of memory for the VM in megabytes"
  default     = 2048
}

variable "gfx_vram_size" {
  type        = number
  description = "VRAM size to allocate"
  default     = 32
}

variable "nic_type" {
  type        = string
  description = "VirtualBox NIC type"
  default     = "82540EM"
}

# Resources and credentials

variable "http_directory" {
  type        = string
  description = "Directory where cloud-init config lives"
  default     = "http"
}

variable "iso_url" {
  type        = string
  description = "URL to download the Ubuntu ISO"
  default     = "https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum for ISO validation"
  default     = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
}

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

variable "ssh_handshake_attempts" {
  type        = number
  description = "Number of SSH connection attempts"
  default     = 10
}

#####################################################################################
# Sources
#####################################################################################

source "virtualbox-iso" "UbuntuServer" {
    # ISO Config
    iso_url                = var.iso_url
    iso_checksum           = var.iso_checksum

    # VM Config
    vm_name                = var.vm_name
    cpus                   = var.cpus
    memory                 = var.memory
    disk_size              = var.disk_size
    nic_type               = var.nic_type
    gfx_vram_size          = var.gfx_vram_size

    # SSH Config 
    ssh_username           = var.ssh_username
    ssh_password           = var.ssh_password
    ssh_timeout            = var.ssh_timeout
    ssh_handshake_attempts = var.ssh_handshake_attempts
    communicator           = var.communicator

    # Boot/Other Config
    guest_os_type          = var.guest_os_type
    format                 = "ovf"
    http_directory         = var.http_directory
    
    boot_wait              = var.boot_wait

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

    shutdown_command       = var.shutdown_command
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
