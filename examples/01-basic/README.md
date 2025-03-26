# Basic Example

Example of using the module with minimal configuration, ie. all default values.

<!-- BEGIN_TF_DOCS -->

```hcl
provider "azurerm" {
  features {
    resource_group {
      # to help with destroy during integration testing
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "gh_vnet" {
  source = "../../"

  github_database_id    = "123456789"
  network_address_space = "10.0.0.0/24"
}
```

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_github_network_settings_id"></a> [github\_network\_settings\_id](#output\_github\_network\_settings\_id) | The resource ID of the GitHub Network settings resource |
| <a name="output_github_network_settings_name"></a> [github\_network\_settings\_name](#output\_github\_network\_settings\_name) | Name of the Github Network settings resource |
| <a name="output_outbound_ip_address"></a> [outbound\_ip\_address](#output\_outbound\_ip\_address) | The outbound NAT public IP address used by runners to access the internet |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | The resource ID of the resource group containing the resources for the Azure Virtual Network (VNet) designed to host GitHub hosted Actions runners |
| <a name="output_virtual_network_resource_id"></a> [virtual\_network\_resource\_id](#output\_virtual\_network\_resource\_id) | The resource ID of the virtual network (VNet) designed to host GitHub hosted Actions runners |
<!-- END_TF_DOCS -->