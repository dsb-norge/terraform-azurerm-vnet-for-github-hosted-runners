output "nat_gateway" {
  description = "Names for nat gateway with the random part (`name_unique`)."
  value       = local.names["nat_gateway"]
}

output "network_security_group" {
  description = "Names for network security group with the random part (`name_unique`)."
  value       = local.names["network_security_group"]
}

output "private_endpoint" {
  description = "Names for private endpoint with the random part (`name_unique`)."
  value       = local.names["private_endpoint"]
}

output "public_ip" {
  description = "Names for public ip with the random part (`name_unique`)."
  value       = local.names["public_ip"]
}

output "resource_group" {
  description = "Names for resource group with the random part (`name_unique`)."
  value       = local.names["resource_group"]
}

output "subnet" {
  description = "Names for subnet with the random part (`name_unique`)."
  value       = local.names["subnet"]
}

output "virtual_network" {
  description = "Names for virtual network with the random part (`name_unique`)."
  value       = local.names["virtual_network"]
}
