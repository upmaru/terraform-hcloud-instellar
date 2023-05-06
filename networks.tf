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
