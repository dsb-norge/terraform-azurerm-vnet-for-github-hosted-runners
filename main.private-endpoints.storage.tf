# Private endpoints for storage accounts
#
locals {
  # map of storage account sub-resource names to partial private link DNS zone names
  storage_subresource_mapping = {
    blob = {
      name          = "blob"
      dns_zone_name = "blob"
    }
    file = {
      name          = "file"
      dns_zone_name = "file"
    }
    queue = {
      name          = "queue"
      dns_zone_name = "queue"
    }
    table = {
      name          = "table"
      dns_zone_name = "table"
    }
    web = {
      name          = "web"
      dns_zone_name = "z1.web"
    }
    dfs = {
      name          = "dfs"
      dns_zone_name = "dfs"
    }
  }

  # the list of DNS records to create for private endpoint to storage accounts are dynamic based on what private endpoint types are enabled
  storage_acc_dns_zones = compact([
    anytrue(values(var.storage_account_private_endpoints)[*].create_blob_pe) ? local.storage_subresource_mapping.blob.dns_zone_name : null,
    anytrue(values(var.storage_account_private_endpoints)[*].create_file_pe) ? local.storage_subresource_mapping.file.dns_zone_name : null,
    anytrue(values(var.storage_account_private_endpoints)[*].create_queue_pe) ? local.storage_subresource_mapping.queue.dns_zone_name : null,
    anytrue(values(var.storage_account_private_endpoints)[*].create_table_pe) ? local.storage_subresource_mapping.table.dns_zone_name : null,
    anytrue(values(var.storage_account_private_endpoints)[*].create_web_pe) ? local.storage_subresource_mapping.web.dns_zone_name : null,
    anytrue(values(var.storage_account_private_endpoints)[*].create_dfs_pe) ? local.storage_subresource_mapping.dfs.dns_zone_name : null,
  ])
}

# create the required private DNS zones for storage accounts
resource "azurerm_private_dns_zone" "storage" {
  for_each = toset(local.storage_acc_dns_zones)

  name                = "privatelink.${each.value}.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
}

# link the private DNS zones to the runner virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  for_each = azurerm_private_dns_zone.storage

  name                  = "${each.value.name}-to-${module.gh_runner_vnet.name}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = module.gh_runner_vnet.resource_id
}

locals {

  # parse resource ids for details
  storage_acc_details = {
    for acc_key, acc_conf in var.storage_account_private_endpoints :
    acc_key => provider::azurerm::parse_resource_id(acc_conf.resource_id)
  }

  # list of sub-resource names required for each storage account
  subresources_per_storage_acc = {
    for acc_key, acc_conf in var.storage_account_private_endpoints :
    acc_key => concat(
      acc_conf.create_blob_pe ? [local.storage_subresource_mapping.blob.name] : [],
      acc_conf.create_file_pe ? [local.storage_subresource_mapping.file.name] : [],
      acc_conf.create_queue_pe ? [local.storage_subresource_mapping.queue.name] : [],
      acc_conf.create_table_pe ? [local.storage_subresource_mapping.table.name] : [],
      acc_conf.create_web_pe ? [local.storage_subresource_mapping.web.name] : [],
      acc_conf.create_dfs_pe ? [local.storage_subresource_mapping.dfs.name] : [],
    )
  }

  # loopable map to create the private endpoints
  storage_pe_configs = merge([
    for acc_key, acc_conf in var.storage_account_private_endpoints :
    {
      for subresource_name in local.subresources_per_storage_acc[acc_key] :
      "${acc_key}-${subresource_name}" => {
        # supplied as input
        account_key         = acc_key
        account_resource_id = acc_conf.resource_id

        # one per enabled subresource type for the account, supplied as input
        subresource_name = subresource_name

        # parsed from the resource id
        account_name    = local.storage_acc_details[acc_key].resource_name
        account_rg_name = local.storage_acc_details[acc_key].resource_group_name

        # go through the mapping to get the correct DNS resource id
        private_dns_zone_id = azurerm_private_dns_zone.storage[local.storage_subresource_mapping[subresource_name].dns_zone_name].id
      }
    }
  ]...)
}

# private endpoint unique names per storage account
module "storage_pe_names" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  for_each = var.storage_account_private_endpoints

  suffix = [var.system_short_name, "storage"]
}

# create the private endpoints for storage accounts
resource "azurerm_private_endpoint" "storage" {
  for_each = local.storage_pe_configs

  name                = "${module.storage_pe_names[each.value.account_key].private_endpoint.name_unique}-${each.value.subresource_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.gh_runner_vnet.subnets.pe_subnet.resource_id

  tags = merge(var.tags, each.value.tags, {
    Description = "PE for storage account '${each.value.account_name}' in resource group '${each.value.account_rg_name}'. Part of the '${var.system_name}' infrastructure for GitHub hosted Actions runners"
  })

  private_service_connection {
    name                           = "storagePrivateLink-${each.value.account_name}-${each.value.subresource_name}"
    private_connection_resource_id = each.value.account_resource_id
    subresource_names              = [each.value.subresource_name]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storagePrivateDnsZoneGroup-${each.value.subresource_name}"
    private_dns_zone_ids = [each.value.private_dns_zone_id]
  }
}
