variable "suffix" {
  description = <<-DESCRIPTION
    Name segments after the resource type slug, joined with "-". The same input
    as `suffix` on Azure/naming/azurerm.

    Example: `["gh-iap-cm", "runners"]` gives `rg-gh-iap-cm-runners` and
    `rg-gh-iap-cm-runners-<random4>`.
    DESCRIPTION
  type        = list(string)
  nullable    = false
}
