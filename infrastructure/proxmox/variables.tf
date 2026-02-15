# ── Proxmox connection ──────────────────────────────────────────────────────

variable "proxmox_host" {
  description = "Proxmox management IP address"
  type        = string
  default     = "172.16.1.158"
}

variable "proxmox_node" {
  description = "Proxmox node name — must match the hostname shown in the web UI sidebar (run: pvecm nodename)"
  type        = string
  default     = "pve"
}

variable "proxmox_username" {
  description = "Proxmox API username (e.g. root@pam)"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox root password — used for both the API and SSH provisioners"
  type        = string
  sensitive   = true
}

variable "proxmox_ssh_user" {
  description = "SSH username for remote-exec provisioners on the Proxmox host"
  type        = string
  default     = "root"
}

variable "proxmox_ssh_password" {
  description = "SSH password for remote-exec provisioners on the Proxmox host"
  type        = string
  sensitive   = true
}

# ── SSH provisioner ─────────────────────────────────────────────────────────

variable "terraform_ssh_private_key_path" {
  description = "Path to the SSH private key used by Terraform provisioners to connect to the LXCs. Must correspond to one of the public keys in lxc_ssh_public_keys / openclaw_ssh_public_keys."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

# ── LXC container ───────────────────────────────────────────────────────────

variable "lxc_vmid" {
  description = "VM ID for the Docker LXC"
  type        = number
  default     = 100
}

variable "lxc_hostname" {
  description = "Hostname inside the Docker LXC"
  type        = string
  default     = "selfhost"
}

variable "lxc_ip" {
  description = "Static IP for the Docker LXC — reuses old TrueNAS IP so no DNS/firewall changes needed"
  type        = string
  default     = "172.16.1.159"
}

variable "lxc_gateway" {
  description = "Default gateway for the Docker LXC"
  type        = string
  default     = "172.16.1.1"
}

variable "nameserver" {
  description = "DNS nameserver for the Docker LXC"
  type        = string
  default     = "172.16.1.1"
}

variable "lxc_memory_mb" {
  description = "RAM allocated to the Docker LXC (MB)"
  type        = number
  default     = 16384
}

variable "lxc_cores" {
  description = "CPU cores allocated to the Docker LXC"
  type        = number
  default     = 8
}

variable "lxc_disk_gb" {
  description = "Root filesystem size for the Docker LXC in GB — lands on local-lvm (Kingston boot SSD)"
  type        = number
  default     = 128
}

variable "lxc_storage" {
  description = "Proxmox storage pool for the LXC root disk"
  type        = string
  default     = "local-lvm"
}

variable "template_storage" {
  description = "Proxmox storage pool where LXC templates are stored"
  type        = string
  default     = "local"
}

variable "lxc_root_password" {
  description = "Root password for the Docker LXC"
  type        = string
  sensitive   = true
}

variable "lxc_ssh_public_keys" {
  description = "SSH public keys to inject into the LXC root account"
  type        = list(string)
  default     = []
}

# ── LXC template (shared by both containers) ────────────────────────────────

variable "lxc_template" {
  description = "Debian LXC template filename — check available names with: pveam update && pveam available --section system | grep debian-13"
  type        = string
  default     = "debian-13-standard_13.1-2_amd64.tar.zst"
}

# ── UID/GID — must match TrueNAS filesystem ownership on fast/tank pools ────

variable "apps_uid" {
  description = "UID for the apps service account (TrueNAS default: 568)"
  type        = number
  default     = 568
}

variable "apps_gid" {
  description = "GID for the apps group (TrueNAS default: 568)"
  type        = number
  default     = 568
}

variable "video_gid" {
  description = "GID for the video group — must match /dev/dri/card0 group ownership on Proxmox host (Debian default: 44)"
  type        = number
  default     = 44
}

variable "render_gid" {
  description = "GID for the render group — must match /dev/dri/renderD* group on Proxmox host (using 110 to avoid tcpdump at 103 and postdrop at 105)"
  type        = number
  default     = 110
}

variable "gpu_card_index" {
  description = "DRI card index for the AMD iGPU — verify with 'ls /dev/dri/'. Determines /dev/dri/card<N> and cgroup2 minor 226:<N>. This machine: card1 → 1."
  type        = number
  default     = 1
}

variable "gpu_render_index" {
  description = "DRI render index for the AMD iGPU — verify with 'ls /dev/dri/'. Determines /dev/dri/renderD<N> and cgroup2 minor 226:<N>. NOTE: NOT always 128+card_index. This machine: renderD128 → 128."
  type        = number
  default     = 128
}

# ── OpenClaw LXC ─────────────────────────────────────────────────────────────

variable "openclaw_vmid" {
  description = "VM ID for the OpenClaw LXC"
  type        = number
  default     = 101
}

variable "openclaw_hostname" {
  description = "Hostname inside the OpenClaw LXC"
  type        = string
  default     = "openclaw"
}

variable "openclaw_ip" {
  description = "Static IP for the OpenClaw LXC"
  type        = string
  default     = "172.16.1.160"
}

variable "openclaw_memory_mb" {
  description = "RAM allocated to the OpenClaw LXC (MB)"
  type        = number
  default     = 4096
}

variable "openclaw_cores" {
  description = "CPU cores allocated to the OpenClaw LXC"
  type        = number
  default     = 4
}

variable "openclaw_disk_gb" {
  description = "Root filesystem size for the OpenClaw LXC (GB)"
  type        = number
  default     = 64
}

variable "openclaw_root_password" {
  description = "Root password for the OpenClaw LXC"
  type        = string
  sensitive   = true
}

variable "openclaw_ssh_public_keys" {
  description = "SSH public keys to inject into the OpenClaw LXC root account"
  type        = list(string)
  default     = []
}
