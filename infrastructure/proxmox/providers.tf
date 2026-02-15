# Proxmox VE 9.1 — Docker LXC with ZFS bind mounts + AMD GPU
#
# Provider: bpg/proxmox v0.95.0 (released 2026-02-08)
# Target:   Proxmox node at var.proxmox_host (172.16.1.158)
#           Docker LXC  at var.lxc_ip        (172.16.1.159, same as old TrueNAS)

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.95"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006/"
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = true # self-signed cert on a fresh Proxmox install

  ssh {
    agent    = false
    username = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
  }
}
