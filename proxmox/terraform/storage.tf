resource "proxmox_storage_nfs" "nas_nfs" {
  id      = "nas-nfs"
  server  = var.nas_ip
  export  = "/volume1/proxmox"
  nodes   = [var.proxmox_node]
  content = ["backup", "images", "iso", "snippets"]
}
