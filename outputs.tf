output "cluster_address" {
  value = "${hcloud_server.bootstrap_node.ipv4_address}:8443"
}

output "trust_token" {
  value = ssh_resource.trust_token.result
}