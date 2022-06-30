# TP4 Devops
## Author : Emile EKANE
## Date : 2020-06-27

## Docs

### Choix technique  

### Difficultés rencontrées  

### Utilisation de Terraform  

**Installation de Terraform**

Pour installer Terraform, Microsoft a pris la peine de nous faire une belle documentation. Pour procéder a son installation, cliquez juste sur le lien suivant : [installer Terraform](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-windows-bash?tabs=bash).  ✨

**Implémentation du code Terraform**  

- Etape 1 :  

Créez un répertoire dans lequelvous allez implémenter votre code Terraform et définissez-le comme répertoire actuel.  

- Etape 2 : 
Créez un fichier nommé `providers.tf`et insérez le code suivant :
```
terraform {

  required_version = ">=0.12"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "765266c6-9a23-4638-af32-dd1e32613047"
}
```  

- Etape 3:
Créez un fichier nommé main.tf et insérer le code suivant:  
```
resource "random_pet" "tp-name" {
  prefix    = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "tp4" {
  name      = random_pet.tp-name.id
  location  = var.resource_group_location
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.tp4.location
  resource_group_name = azurerm_resource_group.tp4.name
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.tp4.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.tp4.location
  resource_group_name = azurerm_resource_group.tp4.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.tp4.location
  resource_group_name = azurerm_resource_group.tp4.name

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
  name                = "myNIC"
  location            = azurerm_resource_group.tp4.location
  resource_group_name = azurerm_resource_group.tp4.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
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
    resource_group = azurerm_resource_group.tp4.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = azurerm_resource_group.tp4.location
  resource_group_name      = azurerm_resource_group.tp4.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

########################################################################################

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                  = "devops-20211212"
  location              = azurerm_resource_group.tp4.location #"france central" 
  resource_group_name   = azurerm_resource_group.tp4.name
  network_interface_ids = [azurerm_network_interface.myterraformnic.id]
  size                  = "Standard_D2s_v3"

  os_disk {
    name                 = "myOsDisk"
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

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
}
```

- Etape 4:
Créez un fichier nommé variables.tf et insérez le code suivant :
```
variable "resource_group_name_prefix" {
  default       = "devops-TP"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  default       = "france central"
  description   = "Location of the resource group."
}
```

- Etape 5:
Créez un fichier nommé output.tf et insérez le code suivant :
```
output "resource_group_name" {
  value = azurerm_resource_group.tp4.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.myterraformvm.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}
```

### Execution with terraform  

- Etape 1 : Initialiser Terraform
```cmd
terraform init
```
Resultat
```cmd
terraform init

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 2.0"...
- Finding latest version of hashicorp/random...       
- Finding latest version of hashicorp/tls...
- Installing hashicorp/azurerm v2.99.0...
- Installed hashicorp/azurerm v2.99.0 (signed by HashiCorp)
- Installing hashicorp/random v3.3.2...
- Installed hashicorp/random v3.3.2 (signed by HashiCorp)
- Installing hashicorp/tls v3.4.0...
- Installed hashicorp/tls v3.4.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl 
to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

"terraform plan" to see
......
```

- Etape 2 : Créer un plan d'éxécution Terraform
```cmd
terraform plan -out main.tfplan
```
Results:
```cmd

```

- Etape 3 : Appliquer le plan d'éxecution
```cmd
terraform apply main.tfplan
```

### Vérifier les résultats   

Pour se connecter a la machine virtuellle , on procède comme suit : 

1. Exécution de la sortie terraform pour obtenir la clé privée SSH et l'enregistrer dans un fichier.
```cmd
terraform output -raw tls_private_key > id_rsa
```  

2. Exécution de la sortie terraform pour obtenir l'adresse IP publique de la machine virtuelle.  
```cmd
terraform output public_ip_address
```
3. Utilisons le SSH pour se connecter a la machine virtuelle.
```cmd
ssh -i id_rsa devops@<public_ip_address>
```
