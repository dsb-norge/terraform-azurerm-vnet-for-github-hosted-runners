# outputs are created to facilitate using this example for integration testing
output "byo_blob_dns_zone_id" {
  description = "The resource ID of the BYO blob DNS zone created in this example"
  value       = azurerm_private_dns_zone.blob.id
}

output "resource_group_name" {
  description = "The name of the resource group created by the module"
  value       = regex("resourceGroups/([^/]+)", module.gh_vnet.virtual_network_resource_id)[0]
}

output "runner_nsg_name" {
  description = "The name of the runner NSG created by the module"
  value       = regex("/([^/]+)$", module.gh_vnet.runner_nsg_resource_id)[0]
}

output "runner_nsg_resource_id" {
  description = "The resource ID of the runner subnet NSG"
  value       = module.gh_vnet.runner_nsg_resource_id
}

output "storage_private_dns_zone_ids" {
  description = "Map of storage sub-resource type to DNS zone resource ID used"
  value       = module.gh_vnet.storage_private_dns_zone_ids
}

output "virtual_network_resource_id" {
  description = "The resource ID of the virtual network"
  value       = module.gh_vnet.virtual_network_resource_id
}

output "vnet_name" {
  description = "The name of the virtual network created by the module"
  value       = regex("/([^/]+)$", module.gh_vnet.virtual_network_resource_id)[0]
}
