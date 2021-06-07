
terraform {
  required_version = ">= 0.12"
  required_providers {
    # Using Azure RM Provider
    azurerm = {
        source = "hashicorp/azurerm"
        version = "=2.46.0"
    }
    # Using Azure null provider
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

resource "azurerm_resource_group" "rg" {
  name = "my-tf"
  location = "australiaeast"
}

resource "null_resource" "getuser" {
  provisioner "local-exec" {
  command     = "$(whoami)  >> ${path.module}/temp"
    interpreter = ["powershell", "-Command"]
  }
}

module "vnet" {
  environment = "prod"
  source = "./module/az-network/"
  projectname = var.projectname
  Owner = "Ajo.Mathew"
  vnetaddressspace = ["10.0.0.0/18"]
  location = azurerm_resource_group.rg.location
  subnets = {
    "fsnet" = "10.0.0.0/21",
    "ssnet" = "10.0.16.0/20"
  }
  rgname = azurerm_resource_group.rg.name
}