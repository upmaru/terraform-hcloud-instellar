provider "hcloud" {
  token = var.hcloud_token
}

locals {
  bootstrap_ip_address = "10.0.1.253"
}


resource "ssh_resource" "trust_token" {
  host         = [for obj in hcloud_server.bootstrap_node.network : upper(obj.ip)][0]
  bastion_host = hcloud_server.bastion.ipv4_address

  user         = "root"
  bastion_user = "root"

  private_key         = tls_private_key.bastion_key.private_key_openssh
  bastion_private_key = tls_private_key.terraform_cloud.private_key_openssh

  commands = [
    "lxc config trust add --name instellar | sed '1d; /^$/d'"
  ]
}

resource "ssh_resource" "cluster_join_token" {
  count        = var.cluster_size
  host         = [for obj in hcloud_server.bootstrap_node.network : upper(obj.ip)][0]
  bastion_host = hcloud_server.bastion.ipv4_address

  user         = "root"
  bastion_user = "root"

  private_key         = tls_private_key.bastion_key.private_key_openssh
  bastion_private_key = tls_private_key.terraform_cloud.private_key_openssh

  commands = [
    "lxc cluster add ${var.cluster_name}-node-${format("%02d", count.index + 1)} | sed '1d; /^$/d'"
  ]
}


resource "hcloud_placement_group" "nodes_group" {
  name = "${var.cluster_name}-instellar-placement"
  type = "spread"

  labels = {
    "cluster_name" = "${var.cluster_name}"
    "platform"     = "instellar"
  }
}

data "cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/templates/cloud-init.tpl", {})
  }
}


resource "hcloud_server" "bootstrap_node" {
  image              = var.image
  name               = "${var.cluster_name}-bootstrap-node"
  location           = var.location
  server_type        = var.node_size
  ssh_keys           = [hcloud_ssh_key.bastion.name]
  placement_group_id = hcloud_placement_group.nodes_group.id
  delete_protection  = true
  rebuild_protection = true
  user_data          = data.cloudinit_config.config.rendered

  lifecycle {
    ignore_changes = [
      location,
      ssh_keys,
      user_data,
      image,
    ]
  }

  connection {
    type                = "ssh"
    user                = "root"
    host                = local.bootstrap_ip_address
    private_key         = tls_private_key.bastion_key.private_key_openssh
    bastion_user        = "root"
    bastion_host        = hcloud_server.bastion.ipv4_address
    bastion_private_key = tls_private_key.terraform_cloud.private_key_openssh
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/lxd-init.yml.tpl", {
      ip_address   = local.bootstrap_ip_address
      server_name  = self.name
      storage_size = "30"
    })

    destination = "/tmp/lxd-init.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "lxd init --preseed < /tmp/lxd-init.yml"
    ]
  }

  labels = {
    "cluster_name" = "${var.cluster_name}"
    "platform"     = "instellar"
    "type"         = "node"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.cluster_vpc.id
    ip         = local.bootstrap_ip_address
  }
}

resource "hcloud_server" "nodes" {
  count              = var.cluster_size
  image              = var.image
  name               = "${var.cluster_name}-node-${format("%02d", count.index + 1)}"
  location           = var.location
  server_type        = var.node_size
  ssh_keys           = [hcloud_ssh_key.bastion.name]
  placement_group_id = hcloud_placement_group.nodes_group.id
  delete_protection  = true
  rebuild_protection = true
  user_data          = data.cloudinit_config.config.rendered

  lifecycle {
    ignore_changes = [
      location,
      ssh_keys,
      user_data,
      image,
    ]
  }

  connection {
    type                = "ssh"
    user                = "root"
    host                = "10.0.1.${count.index + 1}"
    private_key         = tls_private_key.bastion_key.private_key_openssh
    bastion_user        = "root"
    bastion_host        = hcloud_server.bastion.ipv4_address
    bastion_private_key = tls_private_key.terraform_cloud.private_key_openssh
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/lxd-join.yml.tpl", {
      ip_address = "10.0.1.${count.index + 1}"
      join_token = ssh_resource.cluster_join_token[count.index].result
    })

    destination = "/tmp/lxd-join.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "lxd init --preseed < /tmp/lxd-join.yml",
      "shutdown -r +1"
    ]
  }

  labels = {
    "cluster_name" = "${var.cluster_name}"
    "platform"     = "instellar"
    "type"         = "node"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.cluster_vpc.id
    ip         = "10.0.1.${count.index + 1}"
  }
}
