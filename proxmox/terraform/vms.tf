# ---------------------------------------------------------------------------
# VM 1 — Media Stack (Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent)
# ---------------------------------------------------------------------------

resource "proxmox_virtual_environment_vm" "media" {
  name      = "vm-media"
  node_name = var.proxmox_node
  tags      = ["debian", "docker", "media"]

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    datastore_id = var.vm_datastore
    file_id      = proxmox_virtual_environment_download_file.debian_12_cloud.id
    interface    = "virtio0"
    size         = 50
    discard      = "on"
    iothread     = true
  }

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = "${var.vm_media_ip}/24"
        gateway = var.gateway_ip
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init_media.id
  }
}

# ---------------------------------------------------------------------------
# VM 2 — Home/AI Stack (Home Assistant, Immich, Paperless, Ollama, Kasm)
# ---------------------------------------------------------------------------

resource "proxmox_virtual_environment_vm" "home_ai" {
  name      = "vm-home-ai"
  node_name = var.proxmox_node
  tags      = ["debian", "docker", "home-ai"]

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    datastore_id = var.vm_datastore
    file_id      = proxmox_virtual_environment_download_file.debian_12_cloud.id
    interface    = "virtio0"
    size         = 50
    discard      = "on"
    iothread     = true
  }

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = "${var.vm_home_ai_ip}/24"
        gateway = var.gateway_ip
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init_home_ai.id
  }
}

# ---------------------------------------------------------------------------
# VM 3 — Network Stack (Pihole, Unbound, Arcane, NetbootXYZ, ROM Manager)
# Deploy this first — Pihole must be up before other VMs are fully configured
# ---------------------------------------------------------------------------

resource "proxmox_virtual_environment_vm" "network" {
  name      = "vm-network"
  node_name = var.proxmox_node
  tags      = ["debian", "docker", "network"]

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    datastore_id = var.vm_datastore
    file_id      = proxmox_virtual_environment_download_file.debian_12_cloud.id
    interface    = "virtio0"
    size         = 20
    discard      = "on"
    iothread     = true
  }

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = "${var.vm_network_ip}/24"
        gateway = var.gateway_ip
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init_network.id
  }
}
