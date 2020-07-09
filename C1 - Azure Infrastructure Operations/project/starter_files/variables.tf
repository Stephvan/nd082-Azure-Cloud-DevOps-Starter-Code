#Default Location
variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default = "eastus"
}

#Default Resource Group
variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
  default     = "udacity-rg"
}

#Tags
variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    createdBy = "Stephen"
  }
}

variable "prefix" {
  description = "The prefix used for all resources in this example"
  default = "udacity"
}

variable "nb_instances" {
  description = "Specify the number of vm instances"
  default     = "2"
}

