provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x.
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}

/* locals {
  instance_count = 2
} */

#${var.nb_instances}   local.instance_count

#Resource Group
resource "azurerm_resource_group" "rg" {
        name = "${var.resource_group_name}"
        location = "${var.location}"
        tags     = "${var.tags}"
}


#create a virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "${var.prefix}-network"
    address_space       = ["10.0.0.0/16"]
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    tags = "${var.tags}"

}

#create a subnet
resource "azurerm_subnet" "myterraformnetworksubnet" {
  name                 = "${var.prefix}-subnet"
  virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "10.0.1.0/24"
}


#create a public IP address
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "${var.prefix}-pip"
    location                     = azurerm_resource_group.rg.location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Dynamic"

    tags     = "${var.tags}"
}


#Create NSG
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myUdacityNetworkSecurityGroup"
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = azurerm_resource_group.rg.name
    
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

   tags = "${var.tags}"
}


#Create a Network Interface
resource "azurerm_network_interface" "myterraformnic" {
    count                       = "${var.nb_instances}"
    name                        = "${var.prefix}-nic${count.index}"
    location                    = "${azurerm_resource_group.rg.location}"
    resource_group_name         = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "myudacityNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformnetworksubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

   tags = "${var.tags}"
}


# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "myterraformconnectnsgwithnic" {
    count                       = "${var.nb_instances}"
    network_interface_id      = azurerm_network_interface.myterraformnic[count.index].id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}


resource "azurerm_public_ip" "myterrafromlbip" {
  name                = "${var.prefix}-lbpip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
  tags = "${var.tags}"
}

resource "azurerm_lb" "myterraformloadbalancer" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.myterrafromlbip.id
  }

  tags = "${var.tags}"
}

resource "azurerm_lb_backend_address_pool" "myterraformloadbalancerbackendpool" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.myterraformloadbalancer.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_rule" "myterraformnatrule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.myterraformloadbalancer.id
  name                           = "HTTPSAccess"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = azurerm_lb.myterraformloadbalancer.frontend_ip_configuration[0].name
}

resource "azurerm_network_interface_backend_address_pool_association" "myterraformbhnicassociation" {
  count                   = "${var.nb_instances}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.myterraformloadbalancerbackendpool.id
  ip_configuration_name   = "myudacityNicConfiguration"
  network_interface_id    = element(azurerm_network_interface.myterraformnic.*.id, count.index)
}


resource "azurerm_availability_set" "avset" {
  name                         = "${var.prefix}avset"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags = "${var.tags}"
}

#Specify image location
data "azurerm_resource_group" "myterrafromimage" {
  name = "${var.resource_group_name}"
}

data "azurerm_image" "myterrafromimage" {
  name                = "MyUbuntuImage"
  resource_group_name = data.azurerm_resource_group.myterrafromimage.name
}

#Create the VM
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  count                           = "${var.nb_instances}"
  name                            = "${var.prefix}-vm${count.index}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  availability_set_id             = azurerm_availability_set.avset.id
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.myterraformnic[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  /* source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  } */

  source_image_id = data.azurerm_image.myterrafromimage.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

   tags = "${var.tags}"
}


resource "azurerm_managed_disk" "data" {
  count                           = "${var.nb_instances}"
  name                            = "${var.prefix}-md${count.index}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  create_option                   = "Empty"
  disk_size_gb                    = 10
  storage_account_type            = "Standard_LRS"
  tags = "${var.tags}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count                           = "${var.nb_instances}"
  virtual_machine_id = azurerm_linux_virtual_machine.myterraformvm[count.index].id
  managed_disk_id    = azurerm_managed_disk.data[count.index].id
  lun                = 0
  caching            = "None"
}