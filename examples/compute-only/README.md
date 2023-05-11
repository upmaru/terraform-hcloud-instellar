## Basic Usage

Create a terraform script `main.tf` with the following:

```hcl
variable "hcloud_token" {}

module "instellar" {
  source = "upmaru/instellar/hcloud"
  version = "0.3.0"

  hcloud_token = var.hcloud_token
  cluster_name = "fruits"
  vpc_ip_range = "10.0.2.0/24"
  cluster_topology = [
    { id = 1, name = "apple", size = "cpx11" },
    { id = 2, name = "watermelon", size = "cpx11" }
  ]
  node_size    = "cpx11"
  storage_size = 30

  # SSH Keys added to digital account via UI
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
```

Create a file `.auto.tfvars` which should not be checked in with version control and add the credentials

```hcl
hcloud_token = "<your do token>"
```

Simply run

```shell
terraform init
terraform plan
terraform apply
```

The example above will form a cluster with 3 nodes, one node will be called the `bootrap-node` this node will be used to co-ordinate and orchestrate the setup. With this configuration you will get 2 more nodes `apple` and `watermelon`. You can name the node anything you want.

If you wish to add a node into the cluster you can modify the `cluster_topology` variable.

```diff
cluster_topology = [
  {id = 1, name = "apple", size = "cpx11"},
  {id = 2, name = "watermelon", size = "cpx11"},
+ {id = 3, name = "orange", size = "cpx11"}
]
```

Then run `terraform apply` it will automatically scale your cluster up and add `orange` to the cluster. You can also selectively remove a node from the cluster.

```diff
cluster_topology = [
  {id = 1, name = "apple", size = "cpx11"},
- {id = 2, name = "watermelon", size = "cpx11"},
  {id = 3, name = "orange", size = "cpx11"}
]
```

Running `terraform apply` will gracefully remove `watermelon` from the cluster.

### Instance Type

You can specify the type of instance to use by specifying the size in the `cluster_topology`. Please get the size slug from hetzner cloud ui.

```hcl
cluster_topology = [
  {id = 1, name = "apple", size = "cpx11"},
  {id = 2, name = "watermelon", size = "cpx11"},
  {id = 3, name = "orange", size = "cpx11"}
]
```
