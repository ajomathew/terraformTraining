locals {
  basename = var.projectname
  location = {
    "aus" = "australiaeast",
    "us"  = "useast"
  }
  required_software_for_docker = [
    "apt-transport-https", "ca-certificates", "curl", "gnupg-agent", "software-properties-common"
  ]
  docker_packages = [
    "docker-ce", "docker-ce-cli", "containerd.io"
  ]
}

variable "projectname" {
  type        = string
  description = "Project Name"
}

variable "location" {
  type        = string
  description = "Tell me where you want the resources to be \n supported values aus and us"
  default = "aus"
}

variable "admin_username" {
  type = string
  description = "Admin User Name"
}

resource "azurerm_resource_group" "terraform" {
  name     = "${local.basename}-resources"
  location = local.location[var.location]
  # tags = {
  #   owner   = "Ajo Mathew",
  #   project = "Terraform Training"
  # }
}

resource "azurerm_virtual_network" "terraform" {
  name                = "${local.basename}-network"
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
  name                = "${local.basename}-nic"
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
  domain_name_label   = "${var.projectname}"
}

resource "azurerm_linux_virtual_machine" "terraform" {
  name                            = "${local.basename}-machine"
  resource_group_name             = azurerm_resource_group.terraform.name
  location                        = azurerm_resource_group.terraform.location
  size                            = "Standard_B2s"
  admin_username                  = "${var.admin_username}"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.terraform.id,
  ]

  admin_ssh_key {
    username   = "${var.admin_username}"
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

  # Provisioner used to do some post deployment activities in Project
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get remove docker docker-engine docker.io containerd runc",
      "sudo apt-get update",
      "sudo apt-get install ${join(" ", local.required_software_for_docker)} -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "sudo apt-get install ${join(" ", local.docker_packages)} -y",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ${var.admin_username}"
    ]
    # Place connection here to get the scope limited to this provisioner
  }

  # Local run command powerhsell to genreate a file
  provisioner "local-exec" {
    command     = "Get-Date -Format 'dddd MM/dd/yyyy HH:mm K' |Set-Content -Path .\\buildtime"
    interpreter = ["powershell", "-Command"]
  }

  # Copy file over to the newly lauhched VM
  provisioner "file" {
    source      = ".\\buildtime"
    destination = "/home/${var.admin_username}/buildtime"
  }

# Common connection string used for all provisioners
  connection {
    host        = azurerm_public_ip.terraform.fqdn
    type        = "ssh"
    user        = "${var.admin_username}"
    private_key = file("~/.ssh/id_rsa")
  }

}

# Run scrips after resource has been created 
# If on first deployment if you forgot to run scripts on the VM
# resource "null_resource" "missingcommand" {
#   connection {
#     host        = azurerm_public_ip.terraform.fqdn
#     type        = "ssh"
#     user        = "${var.admin_username}"
#     private_key = file("~/.ssh/id_rsa")
#   }
#   provisioner "remote-exec" {
#     inline = [
#       "cat /home/${var.admin_username}/buildtime"
#     ]
#   }
# }

output "vmip" {
  value = "Copy and connect via ssh ${var.admin_username}@${azurerm_public_ip.terraform.fqdn}"
}
