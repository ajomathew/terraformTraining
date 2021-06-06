# Number variables
variable "strgcount" {
  type = number
  description = "The number of storage accounts"
  default = 2
}

# String variable
variable "mystorageName" {
type = string
description = "Prefix for storage account"
}

# List Variables
variable "strgproperties" {
  type = list
  default = ["LRS","Standard"]
}

# Map variables
variable "strglocations" {
  type = map
  default = {
      "us" = "eastus"
      "aus" = "australiaeast"
  }
  description = "Set location of storage account based on location"
}
# Select based on location
variable "selectstrglocation" {
  type = string
  description = "Select aus or us"
}

# Bool
variable "secondsets" {
  type = bool
  description = "Do you need first set of storage accounts"
}
variable "secondsets_count" {
  type = map
  default = {
      "first" = "LRS",
      "second" = "GRS"
  }
}

variable "pricing_select" {
    type = map
    default = {
        "cheap" = "first",
        "redundant" = "second"
    }
    description = "Helping you select type of SKU - Cheap or costly"
}

variable "select" {
  type = string
  description = "Select cheap or redundant"
}

resource "azurerm_resource_group" "rg" {
  name = "mystoog"
  location = "eastus"
}

resource "azurerm_storage_account" "stgaccnt" {
  count = var.secondsets ? var.strgcount : 0
  name = "${var.mystorageName}stgindutu${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
#   location = azurerm_resource_group.rg.location
location = var.strglocations[var.selectstrglocation]
  account_replication_type = "${lookup(var.secondsets_count, var.pricing_select[var.select])}"
  account_tier = var.strgproperties["1"]
}

# Based on bool
resource "azurerm_storage_account" "stgaccnt_second" {
  for_each = var.secondsets_count
  name = "${var.mystorageName}stgindutu${each.key}"
  resource_group_name = azurerm_resource_group.rg.name
#   location = azurerm_resource_group.rg.location
location = var.strglocations[var.selectstrglocation]
  account_replication_type = each.value
  account_tier = var.strgproperties["1"]
}