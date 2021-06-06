locals {
  basename = "${var.projectname}"
  location = {
    "aus" = "australiaeast",
    "us" = "useast"
  }
  required_software_for_docker = [
    "apt-transport-https","ca-certificates","curl","gnupg-agent","software-properties-common"
  ]
  docker_packages = [
    "docker-ce", "docker-ce-cli", "containerd.io"
  ]
}

variable "projectname" {
  type = string
  description = "Project Name"
}

variable "location" {
  type = string
  description = "Tell me where you want the resources to be \n supported values aus and us"
}


resource "azurerm_resource_group" "terraform" {
  name     = "${local.basename}-terraform-resources"
  location = local.location[var.location]
  # tags = {
  #   owner   = "Ajo Mathew",
  #   project = "Terraform Training"
  # }
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

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo apt-get remove docker docker-engine docker.io containerd runc",
      "sudo apt-get update",
      "sudo apt-get install ${join(" ",local.required_software_for_docker)} -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "sudo apt-get install ${join(" ",local.docker_packages)} -y",
      "sudo usermod -aG docker adminuser",
      "sudo systemctl enable docker"
    ]
    connection {
      host = azurerm_public_ip.terraform.fqdn
      type = "ssh"
      user = "adminuser"
      private_key = file("~/.ssh/id_rsa")
    }
  }

}

output "vmip" {
  value = "Copy and connect via ssh adminuser@${azurerm_public_ip.terraform.fqdn}"
}