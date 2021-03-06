
terraform {
  required_version = ">= 0.12"
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        # version = "=2.62.0"
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
