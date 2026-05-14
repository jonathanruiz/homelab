terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.106.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

# ---------------------------------------------------------------------------
# Repository management
# ---------------------------------------------------------------------------

resource "proxmox_apt_standard_repository" "enterprise" {
  node    = var.proxmox_node
  handle  = "pve-enterprise"
  status = false
}

resource "proxmox_apt_standard_repository" "no_subscription" {
  node    = var.proxmox_node
  handle  = "no-subscription"
  status = true
}

resource "proxmox_apt_standard_repository" "ceph_enterprise" {
  node    = var.proxmox_node
  handle  = "ceph-enterprise"
  status = false
}

# ---------------------------------------------------------------------------
# Debian 13 cloud image
# Prerequisite: "local" storage must have "ISO Image" content type enabled
# ---------------------------------------------------------------------------

resource "proxmox_virtual_environment_download_file" "debian_13_cloud" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  file_name    = "debian-13-genericcloud-amd64.img"
}

# ---------------------------------------------------------------------------
# Cloud-init snippets
# Prerequisite: "local" storage must have "Snippets" content type enabled
# In Proxmox UI: Datacenter → Storage → local → Edit → Content → check Snippets
# ---------------------------------------------------------------------------

resource "proxmox_virtual_environment_file" "cloud_init_media" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/cloud-init/media.yaml", {
      ssh_public_key = var.ssh_public_key
      timezone       = var.timezone
    })
    file_name = "cloud-init-media.yaml"
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_home_ai" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/cloud-init/home-ai.yaml", {
      ssh_public_key = var.ssh_public_key
      timezone       = var.timezone
    })
    file_name = "cloud-init-home-ai.yaml"
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_network" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/cloud-init/network.yaml", {
      ssh_public_key = var.ssh_public_key
      timezone       = var.timezone
    })
    file_name = "cloud-init-network.yaml"
  }
}
