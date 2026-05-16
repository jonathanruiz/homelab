# ---------------------------------------------------------------------------
# Workstation VMs — VLAN 50, VM IDs 201–299
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Workstation 1 — Debian 13 Desktop (GNOME + XRDP)
# Access: RDP via Tailscale → 10.0.50.11:3389
# ---------------------------------------------------------------------------

resource "proxmox_virtual_environment_vm" "workstation" {
  name      = "vmwks001"
  node_name = var.proxmox_node
  vm_id     = 201
  tags      = ["debian", "desktop", "workstation"]

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  network_device {
    bridge  = "vmbr0"
    model   = "virtio"
    vlan_id = 50
  }

  disk {
    datastore_id = var.vm_datastore
    file_id      = proxmox_download_file.debian_13_cloud.id
    interface    = "virtio0"
    size         = 30
    discard      = "on"
    iothread     = true
  }

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = "${var.vm_workstation_ip}/24"
        gateway = var.vm_workstation_gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init_workstation.id
  }
}
