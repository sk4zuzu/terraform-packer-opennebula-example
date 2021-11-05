terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.11"
    }
  }
}

variable "resources" {
  type = object({
    vcpu   = string
    memory = string
  })
  default = {
    vcpu   = "2"
    memory = "8192"
  }
}

variable "network" {
  type = object({
    domain  = string
    subnet  = string
    macaddr = string
  })
  default = {
    domain  = "opennebula.local"
    subnet  = "10.11.12.0/24"
    macaddr = "52:54:50:02:00:%02x"
  }
}

variable "storage" {
  type = object({
    directory = string
    artifact  = string
  })
  default = {
    directory = "/stor/opennebula"
    artifact  = "./../../packer/opennebula/.cache/output/packer-opennebula-ubuntu.qcow2"
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "opennebula" {
  name = "opennebula"
  type = "dir"
  path = var.storage.directory
}

resource "libvirt_volume" "opennebula" {
  name   = "opennebula"
  pool   = libvirt_pool.opennebula.name
  format = "qcow2"
  source = var.storage.artifact
}

resource "libvirt_network" "opennebula" {
   name      = "opennebula"
   mode      = "nat"
   domain    = var.network.domain
   addresses = [ var.network.subnet ]
}

resource "libvirt_cloudinit_disk" "opennebula" {
  name = "opennebula.iso"
  pool = libvirt_pool.opennebula.name

  meta_data = <<-EOF
  instance-id: "opennebula"
  local-hostname: "opennebula"
  EOF

  network_config = <<-EOF
  version: 2
  ethernets:
    ens3:
      addresses:
        - "${cidrhost(var.network.subnet, 13)}/${split("/", var.network.subnet)[1]}"
      dhcp4: false
      dhcp6: false
      gateway4: "${cidrhost(var.network.subnet, 1)}"
      macaddress: "${format(var.network.macaddr, 13)}"
      nameservers:
        addresses:
          - "${cidrhost(var.network.subnet, 1)}"
          - "8.8.8.8"
        search:
          - "${var.network.domain}"
  EOF

  user_data = <<-EOF
  #cloud-config
  ssh_pwauth: false
  users:
    - name: ubuntu
      ssh_authorized_keys: "${chomp(file("~/.ssh/id_rsa.pub"))}"
    - name: root
      ssh_authorized_keys: "${chomp(file("~/.ssh/id_rsa.pub"))}"
  chpasswd:
    list:
      - "ubuntu:asd"
    expire: false
  growpart:
    mode: auto
    devices: ["/"]
  write_files:
    - content: |
        net.ipv4.ip_forward = 1
      path: /etc/sysctl.d/98-ip-forward.conf
  runcmd:
    - sysctl -p /etc/sysctl.d/98-ip-forward.conf
  EOF
}

resource "libvirt_domain" "opennebula" {
  name = "opennebula"

  cloudinit = libvirt_cloudinit_disk.opennebula.id

  vcpu   = var.resources.vcpu
  memory = var.resources.memory

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_id     = libvirt_network.opennebula.id
    wait_for_lease = false
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.opennebula.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

provider "null" {}

resource "null_resource" "opennebula" {
  depends_on = [libvirt_domain.opennebula]

  connection {
    type  = "ssh"
    user  = "ubuntu"
    host  = cidrhost(var.network.subnet, 13)
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /terraform/minione --yes --password asd --vm-password asd --marketapp-name 'Alpine Linux 3.14'",
    ]
  }
}
