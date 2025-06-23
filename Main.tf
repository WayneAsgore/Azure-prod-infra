terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.33.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}

module "vnet" {
source = "./modules/networking/vnet"
  vnet_name = var.vnet_name
  location = var.location
  rg_name = var.rg_name
  address_space = var.address_space
}


module "subnet" {
source = "./modules/networking/subnet"
  rg_name = var.rg_name
  subnet_name = var.subnet_name
  subnet_ap = var.subnet_ap
  virtual_network_name = var.vnet_name
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name = var.vm_name
  location = var.vm_location
  size = var.vm_size
  admin_username = var.vm_admin_username
  admin_password = var.vm_admin_password
  resource_group_name = var.rg_name
  disable_password_authentication = false 

  os_disk {
    name = var.os_disk_name
    caching = var.os_disk_caching
    storage_account_type = var.storage_account_type
  }
  
  source_image_reference {
    publisher = var.sir_publisher
    offer = var.sir_offer
    sku = var.sir_sku
    version = var.sir_version
  }
  network_interface_ids = [azurerm_network_interface.nic.id]
}

resource "azurerm_linux_virtual_machine" "linux_worker_vms" {
  for_each = var.linux_worker_vm_map

    name = each.value.name
    location = each.value.location
    size = each.value.size
    admin_username = each.value.admin_username
    admin_password = each.value.admin_password
    resource_group_name = each.value.resource_group_name
    priority = each.value.priority
    eviction_policy = each.value.eviction_policy
    max_bid_price = each.value.max_bid_price
    disable_password_authentication = false
    
    network_interface_ids = [azurerm_network_interface.worker-nic[each.key].id]

    os_disk {
      name = each.value.name
      caching = each.value.os_disk.caching
      storage_account_type = each.value.os_disk.storage_account_type
    }
    source_image_reference {
      publisher = each.value.source_image_reference.publisher
      offer = each.value.source_image_reference.offer
      sku = each.value.source_image_reference.sku
      version = each.value.source_image_reference.version
    }
}

resource "azurerm_public_ip" "public_ip" {
  name                = var.public_ip_name
  location            = var.public_ip_location
  resource_group_name = var.rg_name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
}

resource "azurerm_network_interface" "nic" {
  name                = var.NIC_name
  location            = var.NIC_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = var.NIC_IP_name
    subnet_id                     = module.subnet.subnet_id
    private_ip_address_allocation = var.private_ip
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface" "worker-nic" {
  for_each = var.linux_worker_vm_map

  name = "${each.value.name}-nic"
  location = var.NIC_location
  resource_group_name = var.rg_name

  ip_configuration {
    name = "${each.value.name}-internal"
    subnet_id = module.subnet.subnet_id
    private_ip_address_allocation =  var.private_ip
  }
}

resource "azurerm_network_security_group" "nsg" {

  name = var.nsg_name
  location = var.nsg_location
  resource_group_name = var.rg_name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = var.nsr_name
  priority                    = var.nsr_priority
  direction                   = var.nsr_direction
  access                      = var.nsr_access
  protocol                    = var.nsr_protocol
  source_port_range           = var.nsr_spr
  destination_port_range      = var.nsr_dpr
  source_address_prefix       = var.nsr_sap
  destination_address_prefix  = var.nsr_dap
  resource_group_name         = azurerm_network_security_group.nsg.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_group" "worker-rules" {
  for_each = var.nsg_map

  name = each.value.name
  location = var.location
  resource_group_name = var.rg_name
  
  dynamic "security_rule" {
      for_each = each.value.rules

     content {
      name = security_rule.value.name
      priority = security_rule.value.priority
      direction = security_rule.value.direction
      access = security_rule.value.access
      protocol = security_rule.value.protocol
      source_port_range = security_rule.value.source_port_range
      destination_port_range = security_rule.value.destination_port_range       
      source_address_prefix = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    } 
  }     
}

resource "azurerm_network_interface_security_group_association" "nsg-asso" {
  network_interface_id = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_security_group" "worker-nsg" {
  for_each = var.linux_worker_vm_map

  name = each.value.name
  location = var.nsg_location
  resource_group_name = var.rg_name
}

resource "azurerm_network_interface_security_group_association" "worker-nsg-asso" {
  for_each = var.linux_worker_vm_map

  network_interface_id = azurerm_network_interface.worker-nic[each.key].id
  network_security_group_id = azurerm_network_security_group.worker-nsg[each.key].id
}