# Private endpoints for Databricks
locals {
  need_to_create_dbx_pe = length(var.databricks_private_endpoints) > 0

  # loopable map of supplied configuration with additional details added
  dbx_pe_config = {
    for dbx_name, dbx_conf in var.databricks_private_endpoints :
    dbx_name => merge(dbx_conf, {
      # we parse the id to get the resource name and resource group name
      dbx_details = provider::azurerm::parse_resource_id(dbx_conf.resource_id)
    })
  }
}

# Private DNS zone for Azure Databricks
resource "azurerm_private_dns_zone" "databricks" {
  # Create only one private DNS zone if there is at least one Databricks workspace to link to
  count = local.need_to_create_dbx_pe ? 1 : 0

  name                = "privatelink.azuredatabricks.net"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "databricks" {
  count = local.need_to_create_dbx_pe ? 1 : 0

  name                  = "${module.gh_runner_vnet.name}-to-databricks"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.databricks[0].name
  virtual_network_id    = module.gh_runner_vnet.resource_id
}

# create name for databricks private endpoint
module "dbx_pe_names" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  for_each = local.dbx_pe_config

  suffix = [var.system_short_name, "databricks"]
}

resource "azurerm_private_endpoint" "databricks" {
  for_each = local.dbx_pe_config

  name                = module.dbx_pe_names[each.key].private_endpoint.name_unique
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.gh_runner_vnet.subnets.pe_subnet.resource_id

  tags = merge(var.tags, {
    Description = var.dbx_pe_description_tag != "" ? var.dbx_pe_description_tag : "PE for Azure Databricks '${each.value.dbx_details.resource_name}' in resource group '${each.value.dbx_details.resource_group_name}'. Part of the '${var.system_name}' infrastructure for GitHub hosted Actions runners"
  })

  private_service_connection {
    name                           = "databricksPrivateLink-${each.value.dbx_details.resource_name}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "databricksPrivateDnsZoneGroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.databricks[0].id]
  }
}