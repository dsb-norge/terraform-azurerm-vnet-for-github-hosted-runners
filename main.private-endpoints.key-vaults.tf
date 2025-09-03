# Private endpoints for Azure Key Vault
#
locals {
  need_to_create_kv_pe = length(var.key_vault_private_endpoints) > 0

  # loopable map of supplied configuration with additional details added
  kv_pe_config = {
    for kv_name, kv_conf in var.key_vault_private_endpoints :
    kv_name => merge(kv_conf, {
      # we parse the id to get the resource name and resource group name
      kv_details = provider::azurerm::parse_resource_id(kv_conf.resource_id)
    })
  }
}

# Private DNS zone for Azure Key Vault
resource "azurerm_private_dns_zone" "key_vault" {
  # Create only one private DNS zone if there is at least one key vault to link to
  count = local.need_to_create_kv_pe ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  count = local.need_to_create_kv_pe ? 1 : 0

  name                  = "${module.gh_runner_vnet.name}-to-key-vault"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = module.gh_runner_vnet.resource_id
}

# create name for key vault private endpoint
module "kv_pe_names" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  for_each = local.kv_pe_config

  suffix = [var.system_short_name, "keyvault"]
}

resource "azurerm_private_endpoint" "key_vault" {
  for_each = local.kv_pe_config

  name                = module.kv_pe_names[each.key].private_endpoint.name_unique
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.gh_runner_vnet.subnets.pe_subnet.resource_id

  tags = merge(var.tags, {
    Description = var.key_vault_pe_description_tag != "" ? var.key_vault_pe_description_tag : "PE for Azure Key Vault '${each.value.kv_details.resource_name}' in resource group '${each.value.kv_details.resource_group_name}'. Part of the '${var.system_name}' infrastructure for GitHub hosted Actions runners"
  })

  private_service_connection {
    name                           = "keyVaultPrivateLink-${each.value.kv_details.resource_name}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "keyVaultPrivateDnsZoneGroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault[0].id]
  }
}
