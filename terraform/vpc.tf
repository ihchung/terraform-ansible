terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "1.32.1"       
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.apikey
  region = var.region
}

data "ibm_resource_group" "rg" {
  name = var.resource_group
}

resource ibm_is_vpc "vpc" {
  name = "${var.base_name}-vpc"
  resource_group = data.ibm_resource_group.rg.id
}

data "ibm_is_security_group" "sg" {
  name = ibm_is_vpc.vpc.default_security_group_name
}

# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
  group     = data.ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource ibm_is_subnet "subnet" {
  name = "${var.base_name}-subnet"
  vpc  = ibm_is_vpc.vpc.id
  zone = var.zone
  total_ipv4_address_count = 16
  resource_group = data.ibm_resource_group.rg.id
}

data ibm_is_image "image" {
  name = "ibm-centos-8-3-minimal-amd64-3"
}

data ibm_is_ssh_key "ssh_key" {
   name = var.ssh_key_name
}

resource "ibm_is_instance" "server" {
  name    = "${var.base_name}-server"
  image   = data.ibm_is_image.image.id
  profile = "bx2-2x8"
  vpc     = ibm_is_vpc.vpc.id
  zone    = var.zone
  keys    = [data.ibm_is_ssh_key.ssh_key.id]
  resource_group = data.ibm_resource_group.rg.id

  # fip will be assinged
  primary_network_interface {
    name   = "eth0"
    subnet = ibm_is_subnet.subnet.id
  }
}

resource "ibm_is_floating_ip" "fip" {
  name   = "${var.base_name}-server-fip"
  target = ibm_is_instance.server.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.rg.id
  lifecycle {
    ignore_changes = [resource_group]
  }
}

########################################
# create an inventory file for Ansible #
########################################
resource "local_file" "inventory" {
  content = templatefile("${path.module}/templates/clusterinventory.tpl",
    {
      ansible_sshkey    = var.path_ssh_key
      server_private_ip = ibm_is_instance.server.primary_network_interface[0].primary_ipv4_address
      server_public_ip  = ibm_is_floating_ip.fip.address
  })
  filename        = "${path.module}/../ansible/cluster.inventory"
  file_permission = "0666"
}
