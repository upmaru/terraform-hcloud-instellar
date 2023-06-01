provider "hcloud" {
  token = var.hcloud_token
}

locals {
  user                 = "root"
  bootstrap_ip_address = "10.0.1.253"
  topology = {
    for index, node in var.cluster_topology :
    node.name => node
  }
}

resource "ssh_resource" "trust_token" {
  host         = [for obj in hcloud_server.bootstrap_node.network : upper(obj.ip)][0]
  bastion_host = hcloud_server.bastion.ipv4_address

  user         = local.user
  bastion_user = local.user

  private_key         = tls_private_key.bastion_key.private_key_openssh
  bastion_private_key = tls_private_key.terraform_cloud.private_key_openssh

  commands = [
    "lxc config trust add --name instellar | sed '1d; /^$/d'"
  ]
}

resource "ssh_resource" "cluster_join_token" {
  for_each     = local.topology
  host         = [for obj in hcloud_server.bootstrap_node.network : upper(obj.ip)][0]
  bastion_host = hcloud_server.bastion.ipv4_address

  user         = local.user
  bastion_user = local.user

  private_key         = tls_private_key.bastion_key.private_key_openssh
  bastion_private_key = tls_private_key.terraform_cloud.private_key_openssh

  commands = [
    "lxc cluster add ${var.cluster_name}-node-${each.key} | sed '1d; /^$/d'"
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
    user                = local.user
    host                = local.bootstrap_ip_address
    private_key         = tls_private_key.bastion_key.private_key_openssh
    bastion_user        = local.user
    bastion_host        = hcloud_server.bastion.ipv4_address
    bastion_private_key = tls_private_key.terraform_cloud.private_key_openssh
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/lxd-init.yml.tpl", {
      ip_address   = local.bootstrap_ip_address
      server_name  = self.name
      storage_size = var.storage_size
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
  for_each           = local.topology
  image              = var.image
  name               = "${var.cluster_name}-node-${each.key}"
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
    user                = local.user
    host                = "10.0.1.${each.value.id}"
    private_key         = tls_private_key.bastion_key.private_key_openssh
    bastion_user        = local.user
    bastion_host        = hcloud_server.bastion.ipv4_address
    bastion_private_key = tls_private_key.terraform_cloud.private_key_openssh
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/lxd-join.yml.tpl", {
      ip_address   = "10.0.1.${each.value.id}"
      join_token   = ssh_resource.cluster_join_token[each.key].result
      storage_size = var.storage_size
    })

    destination = "/tmp/lxd-join.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "lxd init --preseed < /tmp/lxd-join.yml",
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
    ip         = "10.0.1.${each.value.id}"
  }
}

resource "ssh_resource" "node_detail" {
  for_each = local.topology

  triggers = {
    always_run = "${timestamp()}"
  }

  host         = [for obj in hcloud_server.bootstrap_node.network : upper(obj.ip)][0]
  bastion_host = hcloud_server.bastion.ipv4_address

  user         = local.user
  bastion_user = local.user

  private_key         = tls_private_key.bastion_key.private_key_openssh
  bastion_private_key = tls_private_key.terraform_cloud.private_key_openssh

  commands = [
    "lxc cluster show ${hcloud_server.nodes[each.key].name}"
  ]
}

resource "terraform_data" "reboot" {
  for_each = local.topology

  input = {
    user                        = local.user
    node_name                   = hcloud_server.nodes[each.key].name
    bastion_private_key         = tls_private_key.bastion_key.private_key_openssh
    bastion_public_ip           = hcloud_server.bastion.ipv4_address
    node_private_ip             = [for obj in hcloud_server.nodes[each.key].network : upper(obj.ip)][0]
    terraform_cloud_private_key = tls_private_key.terraform_cloud.private_key_openssh
    commands = contains(yamldecode(ssh_resource.node_detail[each.key].result).roles, "database-leader") ? ["echo Node is database-leader restarting later", "sudo shutdown -r +1"] : [
      "sudo reboot"
    ]
  }

  connection {
    type                = "ssh"
    user                = self.input.user
    host                = self.input.node_private_ip
    private_key         = self.input.bastion_private_key
    bastion_user        = self.input.user
    bastion_host        = self.input.bastion_public_ip
    bastion_private_key = self.input.terraform_cloud_private_key
    timeout             = "10s"
  }

  provisioner "remote-exec" {
    on_failure = continue
    inline     = self.input.commands
  }
}

resource "terraform_data" "removal" {
  for_each = local.topology

  input = {
    user                        = local.user
    node_name                   = hcloud_server.nodes[each.key].name
    bastion_private_key         = tls_private_key.bastion_key.private_key_openssh
    bastion_public_ip           = hcloud_server.bastion.ipv4_address
    bootstrap_node_private_ip   = [for obj in hcloud_server.bootstrap_node.network : upper(obj.ip)][0]
    terraform_cloud_private_key = tls_private_key.terraform_cloud.private_key_openssh
    commands = contains(yamldecode(ssh_resource.node_detail[each.key].result).roles, "database-leader") ? ["echo ${var.protect_leader ? "Node is database-leader cannot destroy" : "Tearing it all down"}", "exit ${var.protect_leader ? 1 : 0}"] : [
      "lxc cluster remove --force --yes ${hcloud_server.nodes[each.key].name}"
    ]
  }

  depends_on = [
    hcloud_server.bastion,
    hcloud_server.bootstrap_node,
    hcloud_network.cluster_vpc,
    hcloud_network_subnet.cluster_subnet,
    hcloud_firewall.bastion_firewall,
    hcloud_firewall.bastion_firewall
  ]

  connection {
    type                = "ssh"
    user                = self.input.user
    host                = self.input.bootstrap_node_private_ip
    private_key         = self.input.bastion_private_key
    bastion_user        = self.input.user
    bastion_host        = self.input.bastion_public_ip
    bastion_private_key = self.input.terraform_cloud_private_key
    timeout             = "10s"
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = self.input.commands
  }
}
