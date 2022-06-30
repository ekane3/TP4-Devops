
# Create virtual network
data "azurerm_virtual_network" "myterraformnetwork" {
  name                = "example-network"
  resource_group_name = data.azurerm_resource_group.tp4.name
}

# Create subnet
data "azurerm_subnet" "myterraformsubnet" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.tp4.name
  virtual_network_name = data.azurerm_virtual_network.myterraformnetwork.name
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "myPublicIP"
  resource_group_name = data.azurerm_resource_group.tp4.name
  location            = data.azurerm_resource_group.tp4.location
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "myNetworkSecurityGroup"
  location = data.azurerm_resource_group.tp4.location
  resource_group_name = data.azurerm_resource_group.tp4.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
  name = "myNetworkinter"
  location = data.azurerm_resource_group.tp4.location
  resource_group_name = data.azurerm_resource_group.tp4.name

    ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.myterraformnic.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = data.azurerm_resource_group.tp4.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
#data "azurerm_storage_account" "mystorageaccount" {
 # name                     = ""
 # resource_group_name      = data.azurerm_resource_group.tp4.name
#}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

########################################################################################

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                  = "devops-20211212"
  location              = data.azurerm_resource_group.tp4.location #"france central" 
  resource_group_name   = data.azurerm_resource_group.tp4.name
  network_interface_ids = [azurerm_network_interface.myterraformnic.id]
  size                  = "Standard_D2s_v3"

  os_disk {
    name                 = "tp4OsDisk_ter"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vmtp4"
  admin_username                  = "devops"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "devops"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  #boot_diagnostics {
  #  storage_account_uri = data.azurerm_storage_account.mystorageaccount.primary_blob_endpoint
 # }
}