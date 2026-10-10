terraform {
  required_providers {
    # The floor is the one Azure/naming/azurerm 0.4.3 declared. The ceiling keeps
    # callers on random 3.x: every deployed name embeds the results of the two
    # random_string resources, so a major release that replaced them would
    # rename, and so replace, every named Azure resource.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.3.2, < 4.0.0"
    }
  }
}
