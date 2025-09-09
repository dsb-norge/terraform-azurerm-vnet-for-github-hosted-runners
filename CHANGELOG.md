# Changelog

## [2.1.1](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/compare/v2.1.0...v2.1.1) (2025-09-09)


### Bug Fixes

* extend built-in nsg rules for sql private endpoints ([6814b44](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/commit/6814b443715e039884d50792c0044dee1b74154a))

## [2.1.0](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/compare/v2.0.0...v2.1.0) (2025-09-08)


### Features

* support creating private endpoints for azure sql server ([6c417d4](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/commit/6c417d404ae1289cad3b963465121823e2bd3fac))

## [2.0.0](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/compare/v1.1.1...v2.0.0) (2025-09-04)


### ⚠ BREAKING CHANGES

* Introduce tag validation to be sure that tags are not longer than 250 characters (Azure requirement). This requeired upgrade of min version of Terraform to 1.12 feat: possibility to override default Description tag on PE and Network resources, along with BYO tags. docs: README.md Migration notes to v2.x

### Bug Fixes

* Introduce tag validation to be sure that tags are not longer than 250 characters (Azure requirement). This requeired upgrade of min version of Terraform to 1.12 feat: possibility to override default Description tag on PE and Network resources, along with BYO tags. docs: README.md Migration notes to v2.x ([37e7067](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/commit/37e7067134e55446851b2709591c55a97b20c66b))

## [1.1.1](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/compare/v1.1.0...v1.1.1) (2025-08-27)


### Bug Fixes

* wrong private DNS zone for Azure databricks ([#16](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/issues/16)) ([e320ce1](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/commit/e320ce1bd2beea0ed9f5ef89e00b379fdb8a942c))

## [1.1.0](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/compare/v1.0.0...v1.1.0) (2025-08-26)


### Features

* Databricks private endpoint support ([#14](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/issues/14)) ([f6dc66c](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/commit/f6dc66c75e333957754f65e990f5d72832fdb739))

## [1.0.0](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/compare/v0.2.0...v1.0.0) (2025-05-09)


### ⚠ BREAKING CHANGES

* support of virtual network specific tags for Azure IPAM. ([#10](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/issues/10))

### Code Refactoring

* support of virtual network specific tags for Azure IPAM. ([#10](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/issues/10)) ([15cc795](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/commit/15cc79592eda9c7d1387b3e5e3d5efee110ee4b3))

## [0.2.0](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/compare/v0.1.1...v0.2.0) (2025-03-26)


### Features

* **outputs:** add vnet resource id as `virtual_network_resource_id`. ([a19d8e6](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/commit/a19d8e69832bb937b1977d0a80fa2efd643dc5cb))

## [0.1.1](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/compare/v0.1.0...v0.1.1) (2025-03-24)


### Bug Fixes

* harmonize description tags ([9681bab](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/commit/9681babeb6c6dd61a9c0aaf5e861c88b99dec358))

## 0.1.0 (2025-03-21)

### Features

* initial version of the module ([f18fa44](https://github.com/dsb-norge/terraform-azurerm-vnet-for-github-hosted-runners/commit/f18fa4461a6e687151427192c34b86f570ab5ce0))
