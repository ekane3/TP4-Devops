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

Créez un répertoire dans lequel vous allez implémenter votre code Terraform et définissez-le comme répertoire actuel.  

- Etape 2 : 
Créez un fichier nommé `data.tf`et insérez le code suivant :
```
data "azurerm_resource_group" "tp4" {
  name      = "devops-TP2"
}
``` 

- Etape 3 : 
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

- Etape 4:
Créez un fichier nommé main.tf et insérer le code suivant:  
```

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
```

- Etape 5:
Créez un fichier nommé output.tf et insérez le code suivant :
```
output "resource_group_name" {
  value = data.azurerm_resource_group.tp4.name
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
