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
    ip         = "10.0.1.254"
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


