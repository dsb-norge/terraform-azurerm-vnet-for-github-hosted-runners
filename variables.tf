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
    If additional_pe_subnet is provided, it will be used as the second address space for the existing private endpoint subnet.

    Example:
      network_specs = {
        address_space = "10.0.0.1/25"
        additional_pe_subnet = "10.1.0.0/25"
      }
      "/25" means 128 addresses total
      available addresses per subnet = 128 / 2 = 64
      max runner concurrency = 64 - 5 = 59
    DESCRIPTION
  type = object({
    address_space        = string
    additional_pe_subnet = optional(set(string))
    tags                 = optional(map(string))
  })
  validation {
    error_message = "The address space provided in `network_address_space` is not a valid CIDR notation."
    condition     = can(cidrnetmask(var.network_specs.address_space))
  }

  validation {
    error_message = "One or more tags in 'network_specs.tags' exceed 250 characters: ${join(", ", [for k, v in var.network_specs.tags != null ? var.network_specs.tags : {} : k if length(v) > 250])}"
    condition     = var.network_specs.tags == null ? true : alltrue([for t in var.network_specs.tags : length(t) <= 250])
  }

  validation {
    error_message = "If `additional_pe_subnet` is provided in 'network_specs', it must be a valid CIDR notation"
    condition     = var.network_specs.additional_pe_subnet == null ? true : can(cidrnetmask(var.network_specs.additional_pe_subnet))
  }
}

variable "additional_nsg_rules_for_private_endpoint_subnet" {
  description = <<-DESCRIPTION
    Additional NSG rules to add to the built-in NSG for the private endpoint subnet.

    The rules defined here will be added in addition to the built-in rules defined in this module.
    If you use the same rule name as a built-in rule, your rule overrides the built-in definition.
    DESCRIPTION
  type = map(object({
    access                       = string
    description                  = string
    priority                     = number
    protocol                     = string
    direction                    = string
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(set(string))
    source_port_range            = optional(string)
    source_port_ranges           = optional(set(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(set(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(set(string))
  }))
  default  = {}
  nullable = false

  validation {
    error_message = "One or more NSG rule priorities in 'additional_nsg_rules_for_private_endpoint_subnet' are not unique."
    condition     = length(keys(var.additional_nsg_rules_for_private_endpoint_subnet)) == length(distinct([for r in values(var.additional_nsg_rules_for_private_endpoint_subnet) : r.priority]))
  }

  validation {
    error_message = "One or more NSG rule priorities in 'additional_nsg_rules_for_private_endpoint_subnet' are outside the allowed range of 100-4096."
    condition     = alltrue([for r in values(var.additional_nsg_rules_for_private_endpoint_subnet) : r.priority >= 100 && r.priority <= 4096])
  }

  validation {
    # Disallow priority collisions with built-in rules unless user overrides by using built-in rule name.
    condition = alltrue([
      for rule_name, rule in var.additional_nsg_rules_for_private_endpoint_subnet : (
        # If user overrides a built-in rule (same name), allow any priority.
        contains(keys(local.nsg_rules_private_endpoint_subnet_builtin), rule_name)
        ) || (
        # Check for priority collisions with built-in rules.
        !contains(
          values(local.nsg_rules_private_endpoint_subnet_builtin)[*].priority,
          rule.priority
      ))
    ])
    error_message = "One or more NSG rule priorities in 'additional_nsg_rules_for_private_endpoint_subnet' conflict with built-in rules. Change the priority or override the built-in rule by using its name."
  }

  validation {
    condition = alltrue([
      for r in var.additional_nsg_rules_for_private_endpoint_subnet :
      (r.source_address_prefix != null) != (r.source_address_prefixes != null)
    ])
    error_message = "Each rule must set exactly one of source_address_prefix or source_address_prefixes in 'additional_nsg_rules_for_private_endpoint_subnet'."
  }

  validation {
    condition = alltrue([
      for r in var.additional_nsg_rules_for_private_endpoint_subnet :
      (r.source_port_range != null) != (r.source_port_ranges != null)
    ])
    error_message = "Each rule must set exactly one of source_port_range or source_port_ranges in 'additional_nsg_rules_for_private_endpoint_subnet'."
  }

  validation {
    condition = alltrue([
      for r in var.additional_nsg_rules_for_private_endpoint_subnet :
      (r.destination_address_prefix != null) != (r.destination_address_prefixes != null)
    ])
    error_message = "Each rule must set exactly one of destination_address_prefix or destination_address_prefixes in 'additional_nsg_rules_for_private_endpoint_subnet'."
  }

  validation {
    condition = alltrue([
      for r in var.additional_nsg_rules_for_private_endpoint_subnet :
      (r.destination_port_range != null) != (r.destination_port_ranges != null)
    ])
    error_message = "Each rule must set exactly one of destination_port_range or destination_port_ranges in 'additional_nsg_rules_for_private_endpoint_subnet'."
  }
}

variable "additional_nsg_rules_for_runner_subnet" {
  description = <<-DESCRIPTION
    Additional NSG rules to add to the built-in NSG for the GitHub hosted runner subnet.

    The rules defined here will be added in addition to the built-in rules defined in this module.
    If you use the same rule name as a built-in rule, your rule overrides the built-in definition.
    DESCRIPTION
  type = map(object({
    access                       = string
    description                  = string
    priority                     = number
    protocol                     = string
    direction                    = string
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(set(string))
    source_port_range            = optional(string)
    source_port_ranges           = optional(set(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(set(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(set(string))
  }))
  default  = {}
  nullable = false

  validation {
    error_message = "One or more NSG rule priorities in 'additional_nsg_rules_for_runner_subnet' are not unique."
    condition     = length(keys(var.additional_nsg_rules_for_runner_subnet)) == length(distinct([for r in values(var.additional_nsg_rules_for_runner_subnet) : r.priority]))
  }

  validation {
    error_message = "One or more NSG rule priorities in 'additional_nsg_rules_for_runner_subnet' are outside the allowed range of 100-4096."
    condition     = alltrue([for r in values(var.additional_nsg_rules_for_runner_subnet) : r.priority >= 100 && r.priority <= 4096])
  }

  validation {
    # Disallow priority collisions with built-in rules unless user overrides by using built-in rule name.
    condition = alltrue([
      for rule_name, rule in var.additional_nsg_rules_for_runner_subnet : (
        # If user overrides a built-in rule (same name), allow any priority.
        contains(keys(local.nsg_rules_runner_subnet_builtin), rule_name)
        ) || (
        # Check for priority collisions with built-in rules.
        !contains(
          values(local.nsg_rules_runner_subnet_builtin)[*].priority,
          rule.priority
      ))
    ])
    error_message = "One or more NSG rule priorities in 'additional_nsg_rules_for_runner_subnet' conflict with built-in rules. Change the priority or override the built-in rule by using its name."
  }

  validation {
    condition = alltrue([
      for r in var.additional_nsg_rules_for_runner_subnet :
      (r.source_address_prefix != null) != (r.source_address_prefixes != null)
    ])
    error_message = "Each rule must set exactly one of source_address_prefix or source_address_prefixes in 'additional_nsg_rules_for_runner_subnet'."
  }

  validation {
    condition = alltrue([
      for r in var.additional_nsg_rules_for_runner_subnet :
      (r.source_port_range != null) != (r.source_port_ranges != null)
    ])
    error_message = "Each rule must set exactly one of source_port_range or source_port_ranges in 'additional_nsg_rules_for_runner_subnet'."
  }

  validation {
    condition = alltrue([
      for r in var.additional_nsg_rules_for_runner_subnet :
      (r.destination_address_prefix != null) != (r.destination_address_prefixes != null)
    ])
    error_message = "Each rule must set exactly one of destination_address_prefix or destination_address_prefixes in 'additional_nsg_rules_for_runner_subnet'."
  }

  validation {
    condition = alltrue([
      for r in var.additional_nsg_rules_for_runner_subnet :
      (r.destination_port_range != null) != (r.destination_port_ranges != null)
    ])
    error_message = "Each rule must set exactly one of destination_port_range or destination_port_ranges in 'additional_nsg_rules_for_runner_subnet'."
  }
}

variable "databricks_private_endpoints" {
  description = <<-DESCRIPTION
    Map of Databricks workspaces to create private endpoints for.

    Private endpoints will be created for the Databricks workspaces in the GitHub hosted runner virtual network.
    Privatlink private DNS zone for Databricks will also be created and linked to the GitHub hosted runner virtual network.

    DESCRIPTION
  type = map(object({
    resource_id = string
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for dbx_name, dbx_conf in var.databricks_private_endpoints :
      can(provider::azurerm::parse_resource_id(dbx_conf.resource_id))
    ])
    error_message = "One or more Databricks workspace resource IDs in the input 'databricks_private_endpoints' are not valid Azure resource IDs."
  }

  validation {
    error_message = "One or more tags in 'databricks_private_endpoints' exceed 250 characters."
    condition = alltrue([
      for dbx_name, dbx_conf in var.databricks_private_endpoints :
      alltrue([
        for k, v in dbx_conf.tags : length(v) <= 250
      ])
    ])
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
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for kv_name, kv_conf in var.key_vault_private_endpoints :
      can(provider::azurerm::parse_resource_id(kv_conf.resource_id))
    ])
    error_message = "One or more key vault resource IDs in the input 'key_vault_private_endpoints' are not valid Azure resource IDs."
  }

  validation {
    error_message = "One or more tags in 'key_vault_private_endpoints' exceed 250 characters."
    condition = alltrue([
      for kv_name, kv_conf in var.key_vault_private_endpoints :
      alltrue([
        for k, v in kv_conf.tags : length(v) <= 250
      ])
    ])
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

variable "sql_server_private_endpoints" {
  description = <<-DESCRIPTION
    Map of SQL servers to create private endpoints for.

    Private endpoints will be created for the SQL servers in the GitHub hosted runner virtual network.
    Privatlink private DNS zone for SQL servers will also be created and linked to the GitHub hosted runner virtual network.

    NSG rules will be extended to allow traffic for Azure SQL servers configured with 'redirect' connection policy.
      ref. https://learn.microsoft.com/en-us/azure/azure-sql/database/private-endpoint-overview?view=azuresql#use-redirect-connection-policy-with-private-endpoints

    NOTE: The NSG rules are hardcoded to Sql service tags in Norwegian regions. If you need private endpoint(s) to SQL servers in other regions, override the built-in NSG rules with var.nsg_for_runner_subnet.

    DESCRIPTION
  type = map(object({
    resource_id = string
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    error_message = "One or more SQL server resource IDs in the input 'sql_server_private_endpoints' are not valid Azure resource IDs."
    condition = alltrue([
      for sql_name, sql_conf in var.sql_server_private_endpoints :
      can(provider::azurerm::parse_resource_id(sql_conf.resource_id))
    ])
  }

  validation {
    error_message = "One or more tags in 'sql_server_private_endpoints' exceed 250 characters."
    condition = alltrue([
      for sql_name, sql_conf in var.sql_server_private_endpoints :
      alltrue([
        for k, v in sql_conf.tags : length(v) <= 250
    ])])
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
    tags            = optional(map(string), {})
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

  validation {
    error_message = "One or more tags in 'storage_account_private_endpoints' exceed 250 characters."
    condition = alltrue([
      for st_name, st_conf in var.storage_account_private_endpoints :
      alltrue([
        for k, v in st_conf.tags : length(v) <= 250
      ])
    ])
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

  validation {
    error_message = "One or more tags exceed 250 characters: ${join(", ", [for k, v in var.tags : k if v != null && length(v) > 250])}"
    condition     = alltrue([for k, v in var.tags : v != null ? length(v) <= 250 : true])
  }
}
