output "cluster_address" {
  value = "${hcloud_server.bootstrap_node.ipv4_address}:8443"
}

output "trust_token" {
  value = ssh_resource.trust_token.result
}

output "region" {
  value = var.region
}

output "bootstrap_node" {
  value = {
    slug      = hcloud_server.bootstrap_node.name
    public_ip = hcloud_server.bootstrap_node.ipv4_address
  }
}

output "nodes" {
  value = [
    for key, node in hcloud_server.nodes :
    {
      slug      = node.name
      public_ip = node.ipv4_address
    }
  ]
}