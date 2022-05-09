data "azurerm_resource_group" "vm_rg" {
  name = "vm_rg"
}

data "azurerm_subnet" "subnet" {
  name                 = "default"
  virtual_network_name = "my_vnet"
  resource_group_name  = "other_rg"
}

data "azurerm_network_security_group" "nsg" {
  name                = "my_nsg"
  resource_group_name = "other_rg"
}

data "azurerm_key_vault" "kv" {
  name                = "my_vault"
  resource_group_name = "other_rg"
}

data "azurerm_key_vault_secret" "default_password" {
  name         = "defaultPassword"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "lacework_token" {
  name         = "laceworkToken"
  key_vault_id = data.azurerm_key_vault.kv.id
}

variable "network_interface_name" {
  type = string
  default = "my_nic"
}

variable "public_ip_address_name" {
  type = string
  default = "my_pip"
}

variable "virtual_machine_name" {
  type = string
  default = "my_vm_name"
}

variable "virtual_machine_computer_name" {
  type = string
  default = "my_vm_comp_name"
}

variable "virtual_machine_size" {
  type = string
  default = "Standard_B2s"
}

variable "admin_username" {
  type = string
  default = "Administrator"
}

variable "admin_password" {
  type = string
  default = null
  sensitive = true
}

variable "lacework_token" {
  type = string
  default = null
  sensitive = true
}

variable "lacework_endpoint" {
  type = string
  default = "api.lacework.net"
}

variable "lacework_installer" {
  type = string
  default = "https://path/to/LWDataCollector.msi"
}

variable "lacework_defender" {
  type = bool
  default = "false"
}
