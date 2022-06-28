provider "azurerm" {
  features {}
}

locals {
  password = sensitive(var.admin_password == null ? data.azurerm_key_vault_secret.default_password.value : var.admin_password)
  token = sensitive(var.lacework_token == null ? data.azurerm_key_vault_secret.lacework_token.value : var.lacework_token)
  scriptBase = sensitive("powershell -File Install-LWCollector.ps1 -Token ${local.token} -Endpoint ${var.lacework_endpoint} -MsiInstaller ${var.lacework_installer}")
  scriptCommand = sensitive(var.lacework_defender ? "${local.scriptBase} -defender" : local.scriptBase)
}

resource "azurerm_public_ip" "pip" {
  name                    = var.public_ip_address_name
  location                = data.azurerm_resource_group.vm_rg.location
  resource_group_name     = data.azurerm_resource_group.vm_rg.name
  allocation_method       = "Dynamic"
  sku                     = "Basic"
}

resource "azurerm_network_interface" "nic" {
  name                = var.network_interface_name
  location            = data.azurerm_resource_group.vm_rg.location
  resource_group_name = data.azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
    network_interface_id      = azurerm_network_interface.nic.id
    network_security_group_id = data.azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                = var.virtual_machine_name
  location            = data.azurerm_resource_group.vm_rg.location
  resource_group_name = data.azurerm_resource_group.vm_rg.name
  size                = var.virtual_machine_size
  computer_name       = var.virtual_machine_computer_name
  admin_username      = var.admin_username
  admin_password      = local.password
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  enable_automatic_updates = true
  allow_extension_operations = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-smalldisk-g2"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "lacework_dc" {
  name                 = "LaceworkDC"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  protected_settings = <<SETTINGS
    {
        "commandToExecute": "${local.scriptCommand}",
        "fileUris": [
          "https://raw.githubusercontent.com/markfink-lw/azure-resources/master/windows/Install-LWCollector.ps1"
        ]
    }
SETTINGS
}
