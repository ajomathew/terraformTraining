variable "projectname" {
  type = string
  description = "Project Name - This will be prepended to resources"
}

variable "Owner" {
  type = string
  description = "Owner of the Project"
}

variable "environment" {
    # https://www.terraform.io/docs/language/values/variables.html#custom-validation-rules
  type = string
  description = "What is the environment dev/test/prod/uat"
  # Validate if the environment strings are correct
  validation {
      # Reference https://www.terraform.io/docs/language/functions/contains.html
      condition = contains( ["dev","test","prod","uat"] ,var.environment)
    error_message = "The value provided is not in dev,test,prod,uat."
  }
}

variable "vnetaddressspace" {
  type = list
  description = "List of IP address for Vnet"
}

variable "location" {
  type = string
  description = "Location where the subnet needed"
}

variable "subnets" {
  type = map
  description = "Share a map containing the subnets needed for your vnet"
}

variable "rgname" {
  type = string
  description = "Pass Resource Group"
}