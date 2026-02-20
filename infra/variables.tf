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
  description = "Path to the SSH private key used by Terraform provisioners to connect to the LXCs. Must correspond to one of the public keys in lxc_ssh_public_keys / cerebro_ssh_public_keys."
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

# ── Cerebro LXC (Debian 13 + Docker) ───────────────────────────────────────

variable "cerebro_vmid" {
  description = "VM ID for the Cerebro LXC"
  type        = number
  default     = 101
}

variable "cerebro_hostname" {
  description = "Proxmox LXC hostname for Cerebro"
  type        = string
  default     = "cerebro"
}

variable "cerebro_ip" {
  description = "Static IP for the Cerebro LXC"
  type        = string
  default     = "172.16.1.160"
}

variable "cerebro_memory_mb" {
  description = "RAM allocated to the Cerebro LXC (MB)"
  type        = number
  default     = 8192
}

variable "cerebro_cores" {
  description = "CPU cores allocated to the Cerebro LXC"
  type        = number
  default     = 6
}

variable "cerebro_disk_gb" {
  description = "Root filesystem size for the Cerebro LXC (GB)"
  type        = number
  default     = 64
}

variable "cerebro_root_password" {
  description = "Root password for Cerebro LXC provisioning"
  type        = string
  sensitive   = true
}

variable "cerebro_ssh_public_keys" {
  description = "SSH public keys to inject into the Cerebro LXC root account"
  type        = list(string)
  default     = []
}

variable "cerebro_gpu_pci_id" {
  description = "PCI ID(s) for GPU passthrough to Cerebro VM. Format: 0000:bb:dd.f (or semicolon-separated multi-function IDs)."
  type        = string
  default     = ""
}

variable "cerebro_gpu_mapping" {
  description = "Optional Proxmox resource mapping name for GPU passthrough (alternative to cerebro_gpu_pci_id)."
  type        = string
  default     = ""
}
