variable "hcloud_token" {}

locals {
  cluster_name = "fruits"
  provider_name = "hcloud"
}

module "compute" {
  source = "../.."

  hcloud_token = var.hcloud_token
  cluster_name = local.cluster_name
  cluster_topology = [
    {id = 1, name = "01", size = "cpx11"},
    {id = 2, name = "02", size = "cpx11"},
  ]
  node_size = "cpx11"
  storage_size = 30
  ssh_keys = [
    "zacksiri@gmail.com",
    "me@zacksiri.com"
  ]
}

variable "instellar_auth_token" {}

module "instellar" {
  source  = "upmaru/bootstrap/instellar"
  version = "~> 0.3"

  host            = "https://staging-web.instellar.app"
  auth_token      = var.instellar_auth_token
  cluster_name    = local.cluster_name
  region          = module.compute.region
  provider_name   = local.provider_name
  cluster_address = module.compute.cluster_address
  password_token  = module.compute.trust_token

  uplink_channel = "develop"

  bootstrap_node = module.compute.bootstrap_node
  nodes          = module.compute.nodes
}