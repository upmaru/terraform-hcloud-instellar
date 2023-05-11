variable "hcloud_token" {}

module "instellar" {
  source = "../.."

  hcloud_token = var.hcloud_token
  cluster_name = "fruits"
  cluster_topology = [
    {id = 1, name = "apple", size = "cpx11"},
  ]
  node_size = "cpx11"
  storage_size = 30
  ssh_keys = [
    "zacksiri@gmail.com",
    "me@zacksiri.com"
  ]
}

output "trust_token" {
  value = module.instellar.trust_token
}

output "cluster_address" {
  value = module.instellar.cluster_address
}