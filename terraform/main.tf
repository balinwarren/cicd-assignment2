provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "microk8s_rg" {
  name     = "microk8s_rg"
  location = "West US"
}

resource "azurerm_virtual_network" "microk8s_vnet" {
  name                = "microk8s_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.microk8s_rg.location
  resource_group_name = azurerm_resource_group.microk8s_rg.name
}

resource "azurerm_subnet" "microk8s_subnet" {
  name                 = "microk8s_subnet"
  resource_group_name  = azurerm_resource_group.microk8s_rg.name
  virtual_network_name = azurerm_virtual_network.microk8s_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "microk8s_ip" {
  name                = "microk8s_ip"
  location            = azurerm_resource_group.microk8s_rg.location
  resource_group_name = azurerm_resource_group.microk8s_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "microk8s_nic" {
  name                = "microk8s_nic"
  location            = azurerm_resource_group.microk8s_rg.location
  resource_group_name = azurerm_resource_group.microk8s_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.microk8s_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.microk8s_ip.id
  }
}

resource "azurerm_network_security_group" "microk8s_nsg" {
  name                = "microk8s_nsg"
  location            = azurerm_resource_group.microk8s_rg.location
  resource_group_name = azurerm_resource_group.microk8s_rg.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow_ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.microk8s_rg.name
  network_security_group_name = azurerm_network_security_group.microk8s_nsg.name
}

resource "azurerm_network_security_rule" "allow_nodeport_30001" {
  name                        = "allow_nodeport_30001"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "30001"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.microk8s_rg.name
  network_security_group_name = azurerm_network_security_group.microk8s_nsg.name
}

resource "azurerm_network_interface_security_group_association" "microk8s_nic_sg" {
  network_interface_id      = azurerm_network_interface.microk8s_nic.id
  network_security_group_id = azurerm_network_security_group.microk8s_nsg.id
}

resource "azurerm_linux_virtual_machine" "microk8s_vm" {
  name                = "microk8s-vm"
  resource_group_name = azurerm_resource_group.microk8s_rg.name
  location            = azurerm_resource_group.microk8s_rg.location
  size                = "Standard_B2ms"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.microk8s_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  computer_name                   = "microk8s-vm"
  disable_password_authentication = true
}

