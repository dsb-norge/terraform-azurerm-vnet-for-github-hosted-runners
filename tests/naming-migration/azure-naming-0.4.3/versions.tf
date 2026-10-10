terraform {
  required_providers {
    # the constraint Azure/naming 0.4.3 declared
    random = {
      source  = "hashicorp/random"
      version = ">= 3.3.2"
    }
  }
}
