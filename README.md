# Terraform Hetzner Module for Instellar

This module automatically forms LXD cluster on Hetzner Cloud. This terraform module will do the following:

- [x] Setup networking
- [x] Setup bastion node
- [x] Setup compute instances
- [x] Setup Private Key access
- [x] Automatically form a cluster
- [x] Destroy a cluster
- [x] Enable removal of specific nodes gracefully
- [x] Protect against `database-leader` deletion

These functionality come together to enable the user to fully manage LXD cluster using IaC (infrastructure as code)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | ~> 1.38 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | 2.3.2 |
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | 1.38.2 |
| <a name="provider_ssh"></a> [ssh](#provider\_ssh) | 2.6.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [hcloud_firewall.bastion_firewall](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall) | resource |
| [hcloud_firewall.nodes_firewall](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall) | resource |
| [hcloud_network.cluster_vpc](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network) | resource |
| [hcloud_network_subnet.cluster_subnet](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |
| [hcloud_placement_group.nodes_group](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_server.bastion](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server) | resource |
| [hcloud_server.bootstrap_node](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server) | resource |
| [hcloud_server.nodes](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server) | resource |
| [hcloud_ssh_key.bastion](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/ssh_key) | resource |
| [hcloud_ssh_key.terraform_cloud](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/ssh_key) | resource |
| [ssh_resource.cluster_join_token](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/resource) | resource |
| [ssh_resource.node_detail](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/resource) | resource |
| [ssh_resource.trust_token](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/resource) | resource |
| [terraform_data.reboot](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.removal](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [tls_private_key.bastion_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_private_key.terraform_cloud](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [cloudinit_config.config](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_size"></a> [bastion\_size](#input\_bastion\_size) | Size of the bastion instance defaults to Basic 512MB instance https://slugs.do-api.dev/ | `string` | `"cx11"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of your cluster | `any` | n/a | yes |
| <a name="input_cluster_topology"></a> [cluster\_topology](#input\_cluster\_topology) | How many nodes do you want in your cluster? | <pre>list(object({<br>    id   = number<br>    name = string<br>    size = optional(string, "cpx11")<br>  }))</pre> | `[]` | no |
| <a name="input_hcloud_token"></a> [hcloud\_token](#input\_hcloud\_token) | Hetzner Cloud API Token | `any` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | Image type of choice default is Ubuntu 22.04 | `string` | `"ubuntu-22.04"` | no |
| <a name="input_location"></a> [location](#input\_location) | Location of your server | `string` | `"fsn1"` | no |
| <a name="input_node_size"></a> [node\_size](#input\_node\_size) | Type of server you want to provision | `string` | `"cpx11"` | no |
| <a name="input_protect_leader"></a> [protect\_leader](#input\_protect\_leader) | Protect the node marked with database-leader | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | Region of your cluster | `string` | `"eu-central"` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | List of ssh key names | `list(string)` | `[]` | no |
| <a name="input_storage_size"></a> [storage\_size](#input\_storage\_size) | How big is the storage dedicated to the cluster | `any` | n/a | yes |
| <a name="input_subnet_ip_range"></a> [subnet\_ip\_range](#input\_subnet\_ip\_range) | Subnet ip range | `string` | `"10.0.1.0/24"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_address"></a> [cluster\_address](#output\_cluster\_address) | n/a |
| <a name="output_trust_token"></a> [trust\_token](#output\_trust\_token) | n/a |
<!-- END_TF_DOCS -->