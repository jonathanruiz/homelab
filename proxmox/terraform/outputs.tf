output "vm_media_id" {
  description = "VM ID for the Media stack VM"
  value       = proxmox_virtual_environment_vm.media.id
}

output "vm_media_ip" {
  description = "IP address of the Media stack VM"
  value       = var.vm_media_ip
}

output "vm_home_ai_id" {
  description = "VM ID for the Home/AI stack VM"
  value       = proxmox_virtual_environment_vm.home_ai.id
}

output "vm_home_ai_ip" {
  description = "IP address of the Home/AI stack VM"
  value       = var.vm_home_ai_ip
}

output "vm_network_id" {
  description = "VM ID for the Network stack VM"
  value       = proxmox_virtual_environment_vm.network.id
}

output "vm_network_ip" {
  description = "IP address of the Network stack VM (Pihole)"
  value       = var.vm_network_ip
}

output "vm_workstation_id" {
  description = "VM ID for the workstation VM"
  value       = proxmox_virtual_environment_vm.workstation.id
}

output "vm_workstation_ip" {
  description = "IP address of the workstation VM (RDP on port 3389)"
  value       = var.vm_workstation_ip
}
