# Private endpoints for Azure SQL server
#
locals {
  need_to_create_sql_pe = length(var.sql_server_private_endpoints) > 0

  # loopable map of supplied configuration with additional details added
  sql_pe_config = {
    for sql_name, sql_conf in var.sql_server_private_endpoints :
    sql_name => merge(sql_conf, {
      # we parse the id to get the resource name and resource group name
      parsed_id = provider::azurerm::parse_resource_id(sql_conf.resource_id)
      tags      = sql_conf.tags != null ? sql_conf.tags : {}
    })
  }
}

# Private DNS zone for Azure SQL Server
resource "azurerm_private_dns_zone" "sql_server" {
  # Create only one private DNS zone if there is at least one SQL Server to link to
  count = local.need_to_create_sql_pe ? 1 : 0

  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags = merge({
    Description = "Private DNS zone for Azure SQL Server private endpoint connections in the network '${module.gh_runner_vnet.name}'. Part of the '${var.system_name}' infrastructure for GitHub hosted Actions runners"
    },
    var.tags,
  )
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_server" {
  count = local.need_to_create_sql_pe ? 1 : 0

  name                  = "${module.gh_runner_vnet.name}-to-sql-server"
  private_dns_zone_name = azurerm_private_dns_zone.sql_server[0].name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = module.gh_runner_vnet.resource_id
  tags = merge({
    Description = "Link to allow resolution of '${azurerm_private_dns_zone.sql_server[0].name}' in the network '${module.gh_runner_vnet.name}'. Part of the '${var.system_name}' infrastructure for GitHub hosted Actions runners"
    },
    var.tags,
  )
}

# create name for SQL Server private endpoint
module "sql_pe_names" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  for_each = local.sql_pe_config

  suffix = [var.system_short_name, "sqlserver"]
}

resource "azurerm_private_endpoint" "sql_server" {
  for_each = local.sql_pe_config

  location            = azurerm_resource_group.this.location
  name                = module.sql_pe_names[each.key].private_endpoint.name_unique
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.gh_runner_vnet.subnets.pe_subnet.resource_id
  tags = merge({
    Description = "PE for Azure SQL server '${each.value.parsed_id.resource_name}' in resource group '${each.value.parsed_id.resource_group_name}'. Part of the '${var.system_name}' infrastructure for GitHub hosted Actions runners"
    },
    var.tags,
    each.value.tags
  )

  private_service_connection {
    is_manual_connection           = false
    name                           = "sqlServerPrivateLink-${each.value.parsed_id.resource_name}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sqlServerPrivateDnsZoneGroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_server[0].id]
  }
}
