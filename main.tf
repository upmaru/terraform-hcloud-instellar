provider "hcloud" {
  token = var.hcloud_token
}

resource "tls_private_key" "terraform_cloud" {
  algorithm = "ED25519"
}

resource "tls_private_key" "bastion_key" {
  algorithm = "ED25519"
}

resource "hcloud_ssh_key" "terraform_cloud" {
  name       = "${var.cluster_name}-terraform-cloud"
  public_key = tls_private_key.terraform_cloud.public_key_openssh
}

resource "hcloud_ssh_key" "bastion" {
  name       = "${var.cluster_name}-bastion"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

resource "hcloud_network" "cluster_vpc" {
  name     = "${var.cluster_name}-instellar-vpc"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "cluster_subnet" {
  network_id   = hcloud_network.cluster_vpc.id
  type         = "cloud"
  network_zone = var.region
  ip_range     = var.subnet_ip_range
}

resource "hcloud_server" "bastion" {
  image       = var.image
  name        = "${var.cluster_name}-bastion"
  location    = var.location
  server_type = var.bastion_size
  ssh_keys    = concat(var.ssh_keys, [hcloud_ssh_key.terraform_cloud.name])

  labels = {
    "cluster_name" = "${var.cluster_name}"
    "platform"     = "instellar"
    "type"         = "bastion"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.cluster_vpc.id
    ip         = "10.1.0.1"
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    private_key = tls_private_key.terraform_cloud.private_key_openssh
  }

  provisioner "file" {
    content     = tls_private_key.bastion_key.private_key_openssh
    destination = "/root/.ssh/id_ed25519"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /root/.ssh/id_ed25519"
    ]
  }
}


resource "hcloud_placement_group" "nodes_group" {
  name = "${var.cluster_name}-instellar-placement"
  type = "spread"

  labels = {
    "cluster_name" = "${var.cluster_name}"
    "platform"     = "instellar"
  }
}

resource "hcloud_server" "nodes" {
  count              = var.cluster_size
  image              = var.image
  name               = "${var.cluster_name}-node-0${count.index + 1}"
  location           = var.location
  server_type        = var.node_size
  ssh_keys           = [hcloud_ssh_key.bastion.name]
  placement_group_id = hcloud_placement_group.nodes_group.id

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
    ip         = "10.0.1.${count.index} + 1"
  }
}


resource "hcloud_firewall" "nodes_firewall" {
  name = "${var.cluster_name}-instellar-nodes"

  # Enable bastion node to SSH in
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["10.0.0.0/16"]
  }

  # Enable instellar to communicate with nodes
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "8443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "49152"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Enable full cross-node communication tcp
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = ["10.0.0.0/16"]
  }

  # Enable full cross-node communication
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = ["10.0.0.0/16"]
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["10.0.0.0/16"]
  }

  rule {
    direction = "out"
    protocol  = "icmp"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "any"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "udp"
    port      = "any"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  apply_to {
    label_selector = "type=node"
  }
}

resource "hcloud_firewall" "bastion_firewall" {
  name = "${var.cluster_name}-instellar-bastion"

  # SSH from any where
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Enable all outbound traffic
  rule {
    direction = "out"
    protocol  = "icmp"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "any"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "udp"
    port      = "any"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  apply_to {
    label_selector = "type=bastion"
  }
}
