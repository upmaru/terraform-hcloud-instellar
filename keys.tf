resource "tls_private_key" "bastion_key" {
  algorithm = "ED25519"
}

resource "hcloud_ssh_key" "bastion" {
  name       = "${var.cluster_name}-bastion"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

resource "tls_private_key" "terraform_cloud" {
  algorithm = "ED25519"
}

resource "hcloud_ssh_key" "terraform_cloud" {
  name       = "${var.cluster_name}-terraform-cloud"
  public_key = tls_private_key.terraform_cloud.public_key_openssh
}