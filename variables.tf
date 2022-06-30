variable "resource_group_name_prefix" {
  default       = "devops-TP2"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  default       = "france central"
  description   = "Location of the resource group."
}