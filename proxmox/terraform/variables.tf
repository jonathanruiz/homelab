variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = "https://pve001.local.ruizops.com:8006/"
}

variable "proxmox_api_token" {
  description = "Proxmox API token (format: user@realm!token-name=uuid)"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification (set true if using Proxmox self-signed cert)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve001"
}

variable "vm_datastore" {
  description = "Proxmox datastore for VM disks — local storage only, never NFS"
  type        = string
  default     = "local-lvm"
}

variable "snippets_datastore" {
  description = "Proxmox datastore for cloud-init snippets (must have Snippets content type enabled)"
  type        = string
  default     = "local"
}

variable "ssh_public_key" {
  description = "SSH public key injected into all VMs for the deploy user"
  type        = string
}

variable "gateway_ip" {
  description = "Default gateway for all VMs"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers for VMs (will be updated to Pihole IP after VM 3 is up)"
  type        = list(string)
}

variable "vm_media_ip" {
  description = "Static IP for VM 1 (Media stack)"
  type        = string
}

variable "vm_home_ai_ip" {
  description = "Static IP for VM 2 (Home/AI stack)"
  type        = string
}

variable "vm_network_ip" {
  description = "Static IP for VM 3 (Network stack — Pihole, Unbound, Arcane)"
  type        = string
}

variable "timezone" {
  description = "Timezone for all VMs"
  type        = string
}

variable "nas_ip" {
  description = "Synology NAS IP address for NFS storage"
  type        = string
}
