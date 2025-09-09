# Terraform module for creation of Azure Virtual Network for GitHub hosted runners

This module provisions an Azure Virtual Network (VNet) designed to host GitHub hosted Actions runners. It automates the creation and configuration of the necessary network infrastructure components, enabling private networking for GitHub Actions runners within Azure.

The module performs the following actions:

1. **Virtual Network Creation:** Deploys an Azure Virtual Network with a specified address space. It support network space provided by Azure IPAM (mandatory Virtual Network tagging for reservation association)
2. **Subnet Configuration:** Creates two subnets within the VNet:
    * A dedicated subnet for GitHub Actions runners, configured with the `GitHub.Network/networkSettings` delegation, allowing GitHub to manage network interfaces within the subnet.
    * A subnet for private endpoints, facilitating secure access to Azure services.
3. **Network Security Group (NSG) Management:** Configures Network Security Groups (NSGs) for both subnets to control network traffic.  The module provides options to:
    * Create and manage NSGs with default rules.
    * Disable default NSGs and use existing NSGs.
4. **Private Endpoint Support:** Optionally creates private endpoints for already existing Azure services, including:
    * Azure Key Vault
    * Azure Storage Account (blob, file, queue, table, web, dfs)

    The module also manages the creation and vnet linking of private DNS zones for these services.
5. **NAT Gateway Integration:** By default deploys a NAT Gateway and Public IP to provide outbound internet access for the runners. This can be disabled if alternative outbound connectivity is provided.
6. **GitHub Network Settings Resource:** Creates an `azapi_resource` of type `GitHub.Network/networkSettings` to associate the created subnet with a GitHub organization or enterprise, enabling _Azure private networking for GitHub-hosted runners_.
7. **Network Peering:** Supports peering with other Azure Virtual Networks, allowing the runners to access resources in other networks.

This module simplifies the deployment of a secure and isolated network environment for GitHub Actions self-hosted runners in Azure. It provides a configurable and reusable solution for organizations that require private networking for their CI/CD pipelines.

## Usage

Refer to [examples](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/tree/main/examples) for usage of module.

## Migration Notes

### Version 1.X

* **Breaking Change**: The variable `network_address_space` has been renamed to `network_specs` and changed from type `string` to `object`.
  * **Old Configuration**:
  
    ```hcl
    network_address_space = "10.0.0.0/25"
    ```

  * **New Configuration**:
  
    ```hcl
    network_specs = {
      address_space = "10.0.0.0/25"
      tags = {
        IPAMReservation = "IpamReservationID"
      }
    }
    ```

  * Update your configuration to match the new type to avoid errors.
  
### Version 2.X

* **Breaking Change**: Minimum required version of Terraform is 1.12.X

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-disable-file MD013 -->
<!-- markdownlint-disable-file MD033 -->
<!-- markdownlint-disable-file MD037 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.12 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.20 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.network_settings](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway) | resource |
| [azurerm_nat_gateway_public_ip_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_private_dns_zone.databricks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.sql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.databricks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.sql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.databricks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.sql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_github_database_id"></a> [github\_database\_id](#input\_github\_database\_id) | The ID of the GitHub organization / enterprise database, where runners to be deployed.<br/>How to obtain this value depends on if you are creating a vnet for use by a GitHub organization or an enterprise.<br/><br/>To obtain the value for an enterprise, you can use the following GraphQL query with the GitHub CLI:<pre># login to your enterprise:<br/>gh auth login --scopes 'read:enterprise'<br/><br/># define the query<br/>qlQueryBusinessId='query ($slug: String!) { enterprise(slug: $slug) { databaseId }}'<br/>slug='YOUR ENTERPRISE SLUG HERE'<br/><br/># query the api<br/>gh api graphql --field slug="$slug" --raw-field query="$qlQueryBusinessId" --jq '.data.enterprise.databaseId'</pre>To obtain the value for an organization, you can use the following GraphQL query with the GitHub CLI:<pre># login to your organization:<br/>gh auth login<br/><br/># define the query<br/>qlQueryBusinessId='query ($slug: String!) { organization(login: $slug) { databaseId }}'<br/>slug='YOUR ORGANIZATION SLUG HERE'<br/><br/># query the api<br/>gh api graphql --field slug="$slug" --raw-field query="$qlQueryBusinessId" --jq '.data.organization.databaseId'</pre> | `string` | n/a | yes |
| <a name="input_network_specs"></a> [network\_specs](#input\_network\_specs) | The network specs that are used to create Virtual Network for GitHub hosted runners.<br/><br/>The address space will be divided to two subnets: one for runners and one for private endpoints.<br/>Which means: max runner concurrency = vnet\_space / 2 - 5 (addresses that azure reserves for system)<br/>The tags will be added to the virtual network to support Azure IPAM provided address spaces.<br/><br/>Example:<br/>  network\_specs = {<br/>    address\_space = "10.0.0.1/25"<br/>  }<br/>  "/25" means 128 addresses total<br/>  available addresses per subnet = 128 / 2 = 64<br/>  max runner concurrency = 64 - 5 = 59 | <pre>object({<br/>    address_space = string<br/>    tags          = optional(map(string))<br/>  })</pre> | n/a | yes |
| <a name="input_databricks_private_endpoints"></a> [databricks\_private\_endpoints](#input\_databricks\_private\_endpoints) | Map of Databricks workspaces to create private endpoints for.<br/><br/>Private endpoints will be created for the Databricks workspaces in the GitHub hosted runner virtual network.<br/>Privatlink private DNS zone for Databricks will also be created and linked to the GitHub hosted runner virtual network. | <pre>map(object({<br/>    resource_id = string<br/>    tags        = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_disable_builtin_nsg_for_private_endpoint_subnet"></a> [disable\_builtin\_nsg\_for\_private\_endpoint\_subnet](#input\_disable\_builtin\_nsg\_for\_private\_endpoint\_subnet) | Disable the default NSG rule for the private endpoint subnet that is built in to this module.<br/><br/>Note: you can also bring your own NSG rules by using the input variables `nsg_for_runner_subnet` and `nsg_for_private_endpoint_subnet`. | `bool` | `false` | no |
| <a name="input_disable_builtin_nsg_for_runner_subnet"></a> [disable\_builtin\_nsg\_for\_runner\_subnet](#input\_disable\_builtin\_nsg\_for\_runner\_subnet) | Disable the default NSG rule for the GitHub hosted runner subnet that is built in to this module.<br/><br/>Note: you can also bring your own NSG rules by using the input variables `nsg_for_runner_subnet` and `nsg_for_private_endpoint_subnet`. | `bool` | `false` | no |
| <a name="input_disable_nat_gateway"></a> [disable\_nat\_gateway](#input\_disable\_nat\_gateway) | Disable creating resources that allow access to the Internet from the GitHub hosted runner subnet.<br/><br/>By default this module creates a NAT gateway and a public IP to allow the GitHub hosted runners to access the Internet.<br/>By setting this variable to true, these resources will not be created.<br/><br/>NOTE:<br/>  Internet access is required for the GitHub hosted runners to function. If you set this to disabled, you must provide your own means of Internet access. For example via a peered virtual network. | `bool` | `false` | no |
| <a name="input_key_vault_private_endpoints"></a> [key\_vault\_private\_endpoints](#input\_key\_vault\_private\_endpoints) | Map of key vaults to create private endpoints for.<br/><br/>Private endpoints will be created for the key vaults in the GitHub hosted runner virtual network.<br/>Privatlink private DNS zone for key vault will also be created and linked to the GitHub hosted runner virtual network. | <pre>map(object({<br/>    resource_id = string<br/>    tags        = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure Region in which the resources should be deployed. | `string` | `"norwayeast"` | no |
| <a name="input_network_peering_configuration"></a> [network\_peering\_configuration](#input\_network\_peering\_configuration) | Map of peerings to create with other virtual networks.<br/>Leave empty to disable peering.<br/><br/>Supported attributes:<br/>  * `remote_virtual_network_resource_id` - The resource ID of the remote virtual network to peer with.<br/>  * `allow_forwarded_traffic` - Allow forwarded traffic from the remote virtual network. Defaults to false.<br/>  * `allow_gateway_transit` - Allow the local virtual network to receive traffic from the peered virtual networks' gateway or route server. Defaults to false.<br/>  * `allow_virtual_network_access` - Allow virtual network access from the remote virtual network. Defaults to true.<br/>  * `create_reverse_peering` - Creates the reverse peering to form a complete peering. Defaults to false.<br/>  * `reverse_allow_forwarded_traffic` - If you have selected `create_reverse_peering`, enables forwarded traffic between the virtual networks. Defaults to false.<br/>  * `reverse_allow_gateway_transit` - If you have selected `create_reverse_peering`, enables gateway transit for the virtual networks. Defaults to false.<br/>  * `reverse_allow_virtual_network_access` - If you have selected `create_reverse_peering`, enables access from the local virtual network to the remote virtual network. Defaults to true.<br/>  * `reverse_use_remote_gateways` - If you have selected `create_reverse_peering`, enables the use of remote gateways for the virtual networks. Defaults to false.<br/>  * `use_remote_gateways` - Use remote gateways to exchange routes from the remote virtual network. Defaults to false. | <pre>map(object({<br/>    remote_virtual_network_resource_id   = string<br/>    allow_forwarded_traffic              = optional(bool, false)<br/>    allow_gateway_transit                = optional(bool, false)<br/>    allow_virtual_network_access         = optional(bool, true)<br/>    create_reverse_peering               = optional(bool, false)<br/>    reverse_allow_forwarded_traffic      = optional(bool, false)<br/>    reverse_allow_gateway_transit        = optional(bool, false)<br/>    reverse_allow_virtual_network_access = optional(bool, true)<br/>    reverse_use_remote_gateways          = optional(bool, false)<br/>    use_remote_gateways                  = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_nsg_for_private_endpoint_subnet"></a> [nsg\_for\_private\_endpoint\_subnet](#input\_nsg\_for\_private\_endpoint\_subnet) | Resource ID of an already existing network security group to configure for the GitHub hosted runner private endpoint subnet.<br/><br/>This overrides the default NSG rules built in to this module and configures the provided NSG instead.<br/><br/>In combination with the `disable_builtin_nsgs` variable, this allows for complete control over the NSG rules. | <pre>object({<br/>    id = string<br/>  })</pre> | `null` | no |
| <a name="input_nsg_for_runner_subnet"></a> [nsg\_for\_runner\_subnet](#input\_nsg\_for\_runner\_subnet) | Resource ID of an already existing network security group to configure for the GitHub hosted runner subnet.<br/><br/>This overrides the default NSG rules built in to this module and configures the provided NSG instead.<br/><br/>In combination with the `disable_builtin_nsgs` variable, this allows for complete control over the NSG rules. | <pre>object({<br/>    id = string<br/>  })</pre> | `null` | no |
| <a name="input_sql_server_private_endpoints"></a> [sql\_server\_private\_endpoints](#input\_sql\_server\_private\_endpoints) | Map of SQL servers to create private endpoints for.<br/><br/>Private endpoints will be created for the SQL servers in the GitHub hosted runner virtual network.<br/>Privatlink private DNS zone for SQL servers will also be created and linked to the GitHub hosted runner virtual network.<br/><br/>NSG rules will be extended to allow traffic for Azure SQL servers configured with 'redirect' connection policy.<br/>  ref. https://learn.microsoft.com/en-us/azure/azure-sql/database/private-endpoint-overview?view=azuresql#use-redirect-connection-policy-with-private-endpoints<br/><br/>NOTE: The NSG rules are hardcoded to Sql service tags in Norwegian regions. If you need private endpoint(s) to SQL servers in other regions, override the built-in NSG rules with var.nsg\_for\_runner\_subnet. | <pre>map(object({<br/>    resource_id = string<br/>    tags        = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_storage_account_private_endpoints"></a> [storage\_account\_private\_endpoints](#input\_storage\_account\_private\_endpoints) | Map of storage accounts to create private endpoints for.<br/><br/>Private endpoints will be created for the storage accounts in the GitHub hosted runner virtual network.<br/>Privatlink private DNS zone for storage account will also be created and linked to the GitHub hosted runner virtual network.<br/><br/>The following input is expected:<br/>  * `resource_id` - The resource ID of the storage account to create private endpoint for.<br/>  * `create_blob_pe` - Create private endpoint for blob storage. default is false.<br/>  * `create_file_pe` - Create private endpoint for file storage. default is false.<br/>  * `create_queue_pe` - Create private endpoint for queue storage. default is false.<br/>  * `create_table_pe` - Create private endpoint for table storage. default is false.<br/>  * `create_web_pe` - Create private endpoint for web storage. default is false.<br/>  * `create_dfs_pe` - Create private endpoint for dfs storage. default is false.<br/><br/>NOTE: At least one of the storage endpoint sub-resources must be set to true. | <pre>map(object({<br/>    resource_id     = string<br/>    create_blob_pe  = optional(bool, false)<br/>    create_file_pe  = optional(bool, false)<br/>    create_queue_pe = optional(bool, false)<br/>    create_table_pe = optional(bool, false)<br/>    create_web_pe   = optional(bool, false)<br/>    create_dfs_pe   = optional(bool, false)<br/>    tags            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_system_name"></a> [system\_name](#input\_system\_name) | Name used in description tag of resource. | `string` | `"github-hosted-runner-integration"` | no |
| <a name="input_system_short_name"></a> [system\_short\_name](#input\_system\_short\_name) | Name used when generating resource names. | `string` | `"gh-hosted"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_github_network_settings_id"></a> [github\_network\_settings\_id](#output\_github\_network\_settings\_id) | The resource ID of the GitHub Network settings resource, `GitHub.Network/networkSettings`.<br/><br/>Used when creating the GitHub Actions runners network configuration in the GitHub portal.<br/><br/>For GitHub Enterprises, refer to documentation here:<br/>  <https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners-in-your-enterprise#1-add-a-new-network-configuration-for-your-enterprise><br/><br/>For GitHub Organizations, refer to documentation here:<br/>  <https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/configuring-private-networking-for-github-hosted-runners-in-your-organization#creating-a-network-configuration-for-your-organization-in-github> |
| <a name="output_github_network_settings_name"></a> [github\_network\_settings\_name](#output\_github\_network\_settings\_name) | Name of the Github Network settings resource, `GitHub.Network/networkSettings`. |
| <a name="output_outbound_ip_address"></a> [outbound\_ip\_address](#output\_outbound\_ip\_address) | The outbound NAT public IP address used by runners to access the internet.<br/><br/>If `disable_nat_gateway` is set to true, this will be null. |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | The resource ID of the resource group containing the resources for the Azure Virtual Network (VNet) designed to host GitHub hosted Actions runners |
| <a name="output_virtual_network_resource_id"></a> [virtual\_network\_resource\_id](#output\_virtual\_network\_resource\_id) | The resource ID of the virtual network (VNet) designed to host GitHub hosted Actions runners |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dbx_pe_names"></a> [dbx\_pe\_names](#module\_dbx\_pe\_names) | Azure/naming/azurerm | 0.4.2 |
| <a name="module_gh_runner_vnet"></a> [gh\_runner\_vnet](#module\_gh\_runner\_vnet) | Azure/avm-res-network-virtualnetwork/azurerm | 0.8.1 |
| <a name="module_kv_pe_names"></a> [kv\_pe\_names](#module\_kv\_pe\_names) | Azure/naming/azurerm | 0.4.2 |
| <a name="module_runner_name"></a> [runner\_name](#module\_runner\_name) | Azure/naming/azurerm | 0.4.2 |
| <a name="module_sql_pe_names"></a> [sql\_pe\_names](#module\_sql\_pe\_names) | Azure/naming/azurerm | 0.4.2 |
| <a name="module_storage_pe_names"></a> [storage\_pe\_names](#module\_storage\_pe\_names) | Azure/naming/azurerm | 0.4.2 |
| <a name="module_subnet_names"></a> [subnet\_names](#module\_subnet\_names) | Azure/naming/azurerm | 0.4.2 |
<!-- END_TF_DOCS -->