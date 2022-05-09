provider "azurerm" {
  features {}
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

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = var.virtual_machine_name
  location            = data.azurerm_resource_group.vm_rg.location
  resource_group_name = data.azurerm_resource_group.vm_rg.name
  size                = var.virtual_machine_size
  computer_name       = var.virtual_machine_computer_name
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username = var.admin_username
    public_key = data.azurerm_ssh_public_key.ssh_key.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "82gen2"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "lacework_dc" {
  name                 = "LaceworkDC"
  virtual_machine_id   = azurerm_linux_virtual_machine.linux_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  protected_settings = <<SETTINGS
    {
        "commandToExecute": "./install.sh -U https://${var.lacework_endpoint}",
        "fileUris": [
          "https://path/to/install.sh"
        ]
    }
SETTINGS
}
