# The only file that differs between tests/migration/legacy/ and tests/migration/current/.
module "gh_vnet" {
  # 2.5.0: the last release on Azure/naming/azurerm
  source  = "dsb-norge/vnet-for-github-hosted-runners/azurerm"
  version = "2.5.0"

  github_database_id                = local.github_database_id
  network_specs                     = local.network_specs
  storage_account_private_endpoints = local.storage_account_private_endpoints
  system_short_name                 = local.system_short_name
}
