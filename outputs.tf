output "github_network_settings_id" {
  description = <<-DESCRIPTION
    The resource ID of the GitHub Network settings resource, `GitHub.Network/networkSettings`.

    Used when creating the GitHub Actions runners network configuration in the GitHub portal.

    For GitHub Enterprises, refer to documentation here:
      <https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners-in-your-enterprise#1-add-a-new-network-configuration-for-your-enterprise>

    For GitHub Organizations, refer to documentation here:
      <https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/configuring-private-networking-for-github-hosted-runners-in-your-organization#creating-a-network-configuration-for-your-organization-in-github>
    DESCRIPTION
  value       = azapi_resource.network_settings.output.tags.GitHubId
}

output "github_network_settings_name" {
  description = "Name of the Github Network settings resource, `GitHub.Network/networkSettings`."
  value       = azapi_resource.network_settings.output.name
}

output "outbound_ip_address" {
  description = <<-DESCRIPTION
    The outbound NAT public IP address used by runners to access the internet.

    If `disable_nat_gateway` is set to true, this will be null.
    DESCRIPTION
  value       = local.should_create_nat_gateway ? azurerm_public_ip.this[0].ip_address : null
}

output "resource_group_id" {
  description = "The resource ID of the resource group containing the resources for the Azure Virtual Network (VNet) designed to host GitHub hosted Actions runners"
  value       = azurerm_resource_group.this.id
}

output "runner_nsg_resource_id" {
  description = "The resource ID of the runner subnet network security group, or null if no NSG was created by this module."
  value       = local.should_create_nsg_for_runner_subnet ? azurerm_network_security_group.this["runner"].id : null
}

output "storage_private_dns_zone_ids" {
  description = "Map of storage sub-resource type to the private DNS zone resource ID used (module-created or BYO)."
  value = {
    for subresource_name in keys(local.storage_subresource_mapping) :
    subresource_name => (
      contains(keys(var.storage_private_dns_zone_ids), subresource_name)
      ? var.storage_private_dns_zone_ids[subresource_name]
      : azurerm_private_dns_zone.storage[local.storage_subresource_mapping[subresource_name].dns_zone_name].id
    )
    if(
      contains(keys(var.storage_private_dns_zone_ids), subresource_name) ||
      can(azurerm_private_dns_zone.storage[local.storage_subresource_mapping[subresource_name].dns_zone_name].id)
    )
  }
}

output "virtual_network_resource_id" {
  description = "The resource ID of the virtual network (VNet) designed to host GitHub hosted Actions runners"
  value       = module.gh_runner_vnet.resource_id
}
