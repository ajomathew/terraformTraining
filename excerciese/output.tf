
# Set allowed locations
variable "allowed_locations" {
  type = map(any)
  default = {
    "us"  = "eastus",
    "aus" = "australiaeast"
  }
}

# Read location short
variable "selected_location" {
  type        = string
  description = "Selected location of images from us,aus"
  default     = "aus"
}
# Read and set project name
variable "projectname" {
  type        = string
  description = "Project Name"
  default     = "ajom"
}

# Search for ubuntu platform images
data "azurerm_platform_image" "list_ubuntu_image" {
  location  = var.allowed_locations[var.selected_location]
  publisher = "Canonical"
  offer     = "UbuntuServer"
  sku       = "18.04-LTS"
}

# Print image id of ubuntu server
output "image_id" {
  value = data.azurerm_platform_image.list_ubuntu_image.id
}

#Deploying using the id

locals {
  basename = var.projectname
}

resource "azurerm_resource_group" "terraform" {
  name     = "${local.basename}-terraform-resources"
  location = var.allowed_locations[var.selected_location]
}

resource "azurerm_virtual_network" "terraform" {
  name                = "${local.basename}-terraform-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

}

resource "azurerm_subnet" "terraform" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.terraform.name
  virtual_network_name = azurerm_virtual_network.terraform.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "terraform" {
  name                = "${local.basename}-terraform-nic"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terraform.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform.id
  }

}

resource "azurerm_public_ip" "terraform" {
  resource_group_name = azurerm_resource_group.terraform.name
  location            = azurerm_resource_group.terraform.location
  name                = "${local.basename}-pip"
  allocation_method   = "Dynamic"
  domain_name_label   = "ajomvm"
}

resource "azurerm_linux_virtual_machine" "terraform" {
  name                            = "${local.basename}-terraform-machine"
  resource_group_name             = azurerm_resource_group.terraform.name
  location                        = azurerm_resource_group.terraform.location
  size                            = "Standard_B1ls"
  admin_username                  = "adminuser"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.terraform.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  #   source_image_id = lower(data.azurerm_platform_image.list_ubuntu_image.id)
  source_image_reference {
    publisher = data.azurerm_platform_image.list_ubuntu_image.publisher
    offer     = data.azurerm_platform_image.list_ubuntu_image.offer
    sku       = data.azurerm_platform_image.list_ubuntu_image.sku
    version   = data.azurerm_platform_image.list_ubuntu_image.version
  }

}

output "vmip" {
  value = "Copy and connect via ssh adminuser@${azurerm_public_ip.terraform.fqdn}"
}
