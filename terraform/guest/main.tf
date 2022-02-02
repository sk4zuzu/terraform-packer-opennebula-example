terraform {
  required_version = ">= 1.0"
  required_providers {
    opennebula = {
      source = "sk4zuzu/opennebula"
      version = "0.4.0"
    }
  }
}

variable "one" {
  type = object({
    endpoint      = string
    flow_endpoint = string
    username      = string
    password      = string
  })
  default = {
    endpoint      = "http://10.11.12.13:2633/RPC2"
    flow_endpoint = "http://10.11.12.13:2474/RPC2"
    username      = "oneadmin"
    password      = "asd"
  }
}

# FIXME: should not be required
variable "first_run" {
  type    = bool
  default = false
}

provider "opennebula" {
  endpoint      = var.one.endpoint
  flow_endpoint = var.one.flow_endpoint
  username      = var.one.username
  password      = var.one.password
}

data "opennebula_template" "guest" {
  name = "Alpine Linux 3.14"
}

data "opennebula_image" "guest" {
  name = "Alpine Linux 3.14"
}

data "opennebula_virtual_network" "guest" {
  name = "vnet"
}

resource "opennebula_virtual_machine" "guest" {
  name = "guest"

  template_id = data.opennebula_template.guest.id

  memory = 1024

  dynamic "disk" {
    for_each = var.first_run ? [] : [1] # FIXME: should not be required
    content {
      image_id = data.opennebula_image.guest.id
      size     = 1024
    }
  }

  dynamic "nic" {
    for_each = var.first_run ? [] : [1] # FIXME: should not be required
    content {
      network_id = data.opennebula_virtual_network.guest.id
    }
  }

  timeout = 5
}
