terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.106.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state"
    key    = "proxmox/terraform.tfstate"
    region = "garage"
    endpoint                    = "https://garage.local.ruizops.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent    = true
    username = var.promxmox_ssh_user
  }
}

# ---------------------------------------------------------------------------
# Debian 13 cloud image
# Prerequisite: "local" storage must have "ISO Image" content type enabled
# ---------------------------------------------------------------------------

resource "proxmox_download_file" "debian_13_cloud" {
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
