#provider variable
variable subscription_id {}

#vnet variables
variable vnet_name {}
variable location {}
variable address_space {}

#subnet variables
variable subnet_name {}
variable subnet_ap {}

#linux vm variables
variable vm_name {}
variable vm_location {}
variable vm_size {}
variable vm_admin_username {}
variable vm_admin_password {}
    
    #os_disk
    variable os_disk_name {}
    variable os_disk_caching {}
    variable storage_account_type {}

    #source_image_reference
    variable sir_publisher {}
    variable sir_offer {}
    variable sir_sku {}
    variable sir_version {}

#NIC variables
variable NIC_name {}
variable NIC_location {}

    #NIC IP configuration
    variable NIC_IP_name {}
    variable private_ip {}


#Public IP variables
variable public_ip_name {}
variable public_ip_location {}
variable public_ip_allocation_method {}
variable public_ip_sku {}

#NSG variables
variable nsg_name {}
variable nsg_location {}

#NSR variables
variable nsr_name {}
variable nsr_priority {}
variable nsr_direction {}
variable nsr_access {}
variable nsr_protocol {}
variable nsr_spr {}
variable nsr_dpr {}
variable nsr_sap {}
variable nsr_dap {}

#rg_name
variable rg_name {}

#Mapping
variable "linux_worker_vm_map" {
    type = map(object({
      name = string
      location = string
      size = string
      admin_username = string
      admin_password = string
      resource_group_name = string
      priority = string
      eviction_policy = string
      max_bid_price = string
      disable_password_authentication = bool
      os_disk = object({
        name = string
        caching = string
        storage_account_type = string
      })
      source_image_reference = object({
        publisher = string
        offer = string
        sku = string
        version = string
      })
    }))        
}

variable "nsg_map" {
  type = map(object({
    name = string
    rules = list(object({
      name = string
      priority = number
      direction = string
      access = string
      protocol = string
      source_port_range = string
      destination_port_range = number      
      source_address_prefix = string
      destination_address_prefix = string
  }))
  }))
}

variable "lb_rules_map" {
  type = map(object({
  name                           = string
  protocol                       = string
  frontend_port                  = number
  backend_port                   = number
  frontend_ip_configuration_name = string
  }))
}



