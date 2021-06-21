output "az-network-id" {
  value = azurerm_virtual_network.vnet.id
}

output "az-subnet-all" {
  value = azurerm_subnet.subnet
}

output "az-subnet-formated" {
  value = [for snet in azurerm_subnet.subnet : {"address_prefix"=snet.address_prefix, "id"=snet.id}]
}