resource "azurerm_virtual_network" "vnet" {
  name = "${var.projectname}${var.environment}-vnet"
  address_space = var.vnetaddressspace
  location = var.location
  resource_group_name = var.rgname
}

resource "azurerm_subnet" "subnet" {
  for_each = var.subnets
  name = "${var.projectname}${var.environment}-${each.key}-snet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ "${each.value}" ]
  resource_group_name = var.rgname
}