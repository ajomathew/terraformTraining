
terraform {
  required_version = ">= 0.12"
  required_providers {
    # Using Azure RM Provider
    azurerm = {
        source = "hashicorp/azurerm"
        version = "=2.46.0"
    }
    # Using null provider
    null = {
      source = "hashicorp/null"
    }
  }
}

provider azurerm{
    features {
      virtual_machine {
        delete_os_disk_on_deletion = true
      }
    }
}
