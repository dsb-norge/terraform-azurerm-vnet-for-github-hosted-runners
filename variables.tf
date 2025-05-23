variable "github_database_id" {
  description = <<-DESCRIPTION
    The ID of the GitHub organization / enterprise database, where runners to be deployed.
    How to obtain this value depends on if you are creating a vnet for use by a GitHub organization or an enterprise.

    To obtain the value for an enterprise, you can use the following GraphQL query with the GitHub CLI:

    ```
    # login to your enterprise:
    gh auth login --scopes 'read:enterprise'

    # define the query
    qlQueryBusinessId='query ($slug: String!) { enterprise(slug: $slug) { databaseId }}'
    slug='YOUR ENTERPRISE SLUG HERE'

    # query the api
    gh api graphql --field slug="$slug" --raw-field query="$qlQueryBusinessId" --jq '.data.enterprise.databaseId'
    ```

    To obtain the value for an organization, you can use the following GraphQL query with the GitHub CLI:

    ```
    # login to your organization:
    gh auth login

    # define the query
    qlQueryBusinessId='query ($slug: String!) { organization(login: $slug) { databaseId }}'
    slug='YOUR ORGANIZATION SLUG HERE'

    # query the api
    gh api graphql --field slug="$slug" --raw-field query="$qlQueryBusinessId" --jq '.data.organization.databaseId'
    ```
    DESCRIPTION
  type        = string
  nullable    = false

  validation {
    condition     = length(var.github_database_id) > 0
    error_message = "The github_database_id variable cannot be empty."
  }
}

variable "network_specs" {
  description = <<-DESCRIPTION
    The network specs that are used to create Virtual Network for GitHub hosted runners.

    The address space will be divided to two subnets: one for runners and one for private endpoints.
    Which means: max runner concurrency = vnet_space / 2 - 5 (addresses that azure reserves for system)
    The tags will be added to the virtual network to support Azure IPAM provided address spaces.

    Example:
      network_specs = {
        address_space = "10.0.0.1/25"
      }
      "/25" means 128 addresses total
      available addresses per subnet = 128 / 2 = 64
      max runner concurrency = 64 - 5 = 59
    DESCRIPTION
  type = object({
    address_space = string
    tags          = optional(map(string))
  })
  validation {
    error_message = "The address space provided in `network_address_space` is not a valid CIDR notation."
    condition     = can(cidrnetmask(var.network_specs.address_space))
  }
}

variable "disable_builtin_nsg_for_private_endpoint_subnet" {
  description = <<-DESCRIPTION
    Disable the default NSG rule for the private endpoint subnet that is built in to this module.

    Note: you can also bring your own NSG rules by using the input variables `nsg_for_runner_subnet` and `nsg_for_private_endpoint_subnet`.
    DESCRIPTION
  type        = bool
  default     = false
  nullable    = false
}

variable "disable_builtin_nsg_for_runner_subnet" {
  description = <<-DESCRIPTION
    Disable the default NSG rule for the GitHub hosted runner subnet that is built in to this module.

    Note: you can also bring your own NSG rules by using the input variables `nsg_for_runner_subnet` and `nsg_for_private_endpoint_subnet`.
    DESCRIPTION
  type        = bool
  default     = false
  nullable    = false
}

variable "disable_nat_gateway" {
  description = <<-DESCRIPTION
    Disable creating resources that allow access to the Internet from the GitHub hosted runner subnet.

    By default this module creates a NAT gateway and a public IP to allow the GitHub hosted runners to access the Internet.
    By setting this variable to true, these resources will not be created.

    NOTE:
      Internet access is required for the GitHub hosted runners to function. If you set this to disabled, you must provide your own means of Internet access. For example via a peered virtual network.
    DESCRIPTION
  type        = bool
  default     = false
  nullable    = false
}

variable "key_vault_private_endpoints" {
  description = <<-DESCRIPTION
    Map of key vaults to create private endpoints for.

    Private endpoints will be created for the key vaults in the GitHub hosted runner virtual network.
    Privatlink private DNS zone for key vault will also be created and linked to the GitHub hosted runner virtual network.

    DESCRIPTION
  type = map(object({
    resource_id = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for kv_name, kv_conf in var.key_vault_private_endpoints :
      can(provider::azurerm::parse_resource_id(kv_conf.resource_id))
    ])
    error_message = "One or more key vault resource IDs in the input 'key_vault_private_endpoints' are not valid Azure resource IDs."
  }
}

variable "location" {
  description = "The Azure Region in which the resources should be deployed."
  type        = string
  default     = "norwayeast"
  nullable    = false

  validation {
    condition     = length(var.location) > 0
    error_message = "The location variable cannot be empty."
  }
}

variable "network_peering_configuration" {
  description = <<-DESCRIPTION
    Map of peerings to create with other virtual networks.
    Leave empty to disable peering.

    Supported attributes:
      * `remote_virtual_network_resource_id` - The resource ID of the remote virtual network to peer with.
      * `allow_forwarded_traffic` - Allow forwarded traffic from the remote virtual network. Defaults to false.
      * `allow_gateway_transit` - Allow the local virtual network to receive traffic from the peered virtual networks' gateway or route server. Defaults to false.
      * `allow_virtual_network_access` - Allow virtual network access from the remote virtual network. Defaults to true.
      * `create_reverse_peering` - Creates the reverse peering to form a complete peering. Defaults to false.
      * `reverse_allow_forwarded_traffic` - If you have selected `create_reverse_peering`, enables forwarded traffic between the virtual networks. Defaults to false.
      * `reverse_allow_gateway_transit` - If you have selected `create_reverse_peering`, enables gateway transit for the virtual networks. Defaults to false.
      * `reverse_allow_virtual_network_access` - If you have selected `create_reverse_peering`, enables access from the local virtual network to the remote virtual network. Defaults to true.
      * `reverse_use_remote_gateways` - If you have selected `create_reverse_peering`, enables the use of remote gateways for the virtual networks. Defaults to false.
      * `use_remote_gateways` - Use remote gateways to exchange routes from the remote virtual network. Defaults to false.
    DESCRIPTION
  type = map(object({
    remote_virtual_network_resource_id   = string
    allow_forwarded_traffic              = optional(bool, false)
    allow_gateway_transit                = optional(bool, false)
    allow_virtual_network_access         = optional(bool, true)
    create_reverse_peering               = optional(bool, false)
    reverse_allow_forwarded_traffic      = optional(bool, false)
    reverse_allow_gateway_transit        = optional(bool, false)
    reverse_allow_virtual_network_access = optional(bool, true)
    reverse_use_remote_gateways          = optional(bool, false)
    use_remote_gateways                  = optional(bool, false)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for peering_name, peering_conf in var.network_peering_configuration :
      can(provider::azurerm::parse_resource_id(peering_conf.remote_virtual_network_resource_id))
    ])
    error_message = <<-ERRORMESSAGE
      All remote virtual network resource IDs must be valid Azure resource IDs.

      Example of a valid resource ID:
        /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet
      ERRORMESSAGE
  }
}

variable "nsg_for_private_endpoint_subnet" {
  description = <<-DESCRIPTION
    Resource ID of an already existing network security group to configure for the GitHub hosted runner private endpoint subnet.

    This overrides the default NSG rules built in to this module and configures the provided NSG instead.

    In combination with the `disable_builtin_nsgs` variable, this allows for complete control over the NSG rules.
    DESCRIPTION
  type = object({
    id = string
  })
  default = null

  validation {
    condition     = var.nsg_for_private_endpoint_subnet == null || can(provider::azurerm::parse_resource_id(var.nsg_for_private_endpoint_subnet.id))
    error_message = "The provided NSG resource ID is not a valid Azure resource ID."
  }
}

variable "nsg_for_runner_subnet" {
  description = <<-DESCRIPTION
    Resource ID of an already existing network security group to configure for the GitHub hosted runner subnet.

    This overrides the default NSG rules built in to this module and configures the provided NSG instead.

    In combination with the `disable_builtin_nsgs` variable, this allows for complete control over the NSG rules.
    DESCRIPTION
  type = object({
    id = string
  })
  default = null

  validation {
    condition     = var.nsg_for_runner_subnet == null || can(provider::azurerm::parse_resource_id(var.nsg_for_runner_subnet.id))
    error_message = "The provided NSG resource ID is not a valid Azure resource ID."
  }
}

variable "storage_account_private_endpoints" {
  description = <<-DESCRIPTION
    Map of storage accounts to create private endpoints for.

    Private endpoints will be created for the storage accounts in the GitHub hosted runner virtual network.
    Privatlink private DNS zone for storage account will also be created and linked to the GitHub hosted runner virtual network.

    The following input is expected:
      * `resource_id` - The resource ID of the storage account to create private endpoint for.
      * `create_blob_pe` - Create private endpoint for blob storage. default is false.
      * `create_file_pe` - Create private endpoint for file storage. default is false.
      * `create_queue_pe` - Create private endpoint for queue storage. default is false.
      * `create_table_pe` - Create private endpoint for table storage. default is false.
      * `create_web_pe` - Create private endpoint for web storage. default is false.
      * `create_dfs_pe` - Create private endpoint for dfs storage. default is false.

    NOTE: At least one of the storage endpoint sub-resources must be set to true.
    DESCRIPTION
  type = map(object({
    resource_id     = string
    create_blob_pe  = optional(bool, false)
    create_file_pe  = optional(bool, false)
    create_queue_pe = optional(bool, false)
    create_table_pe = optional(bool, false)
    create_web_pe   = optional(bool, false)
    create_dfs_pe   = optional(bool, false)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for st_name, st_conf in var.storage_account_private_endpoints :
      anytrue([
        st_conf.create_blob_pe,
        st_conf.create_file_pe,
        st_conf.create_queue_pe,
        st_conf.create_table_pe,
        st_conf.create_web_pe,
        st_conf.create_dfs_pe
      ])
    ])
    error_message = "At least one of the storage endpoint sub-resources must be set to true for each storage account provided."
  }

  validation {
    condition = alltrue([
      for st_name, st_conf in var.storage_account_private_endpoints :
      can(provider::azurerm::parse_resource_id(st_conf.resource_id))
    ])
    error_message = "One or more storage account resource IDs in the input 'storage_account_private_endpoints' are not valid Azure resource IDs."
  }
}

variable "system_name" {
  description = "Name used in description tag of resource."
  type        = string
  default     = "github-hosted-runner-integration"
  nullable    = false

  validation {
    condition     = length(var.system_name) > 0
    error_message = "The system_name variable cannot be empty."
  }
}

variable "system_short_name" {
  description = "Name used when generating resource names."
  type        = string
  default     = "gh-hosted"
  nullable    = false

  validation {
    condition     = length(var.system_short_name) > 0
    error_message = "The system_short_name variable cannot be empty."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for k, v in var.tags : length(k) > 0])
    error_message = "Empty key found in the map 'tags', this is not allowed."
  }

  validation {
    condition     = alltrue([for k, v in var.tags : v != null ? length(v) > 0 : false])
    error_message = "One or more null or empty string values found in the map 'tags', this is not allowed."
  }
}
