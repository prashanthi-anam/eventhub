variable "resource_group" {
    description = "resourcegrp name"
    type = string
  
}
variable "location" {
    description = "location of resource"
    type = string
  
}

variable "vnet_address_space" {
  description = "adress space for vnet"
  type = string
  
}
variable "subnet_address_prefix" {
  description = "adress space for subnet"
  type = string
}
variable "account_tier" {
  description = "storage account of account tier"
  type = string
  
}
variable "account_replication_type" {
  description = "account_replication_type"
  type = string
  
}
variable "sku" {
    description = "sku of eventhub"
    type = string
   
  
}
variable "lock_level" {
    description = "locklevel"
    type = string
    
  
}