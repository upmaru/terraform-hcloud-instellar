## Basic Usage

Create a terraform script `main.tf` with the following:

```hcl
variable "hcloud_token" {}

locals {
  // replace with your cluster name
  cluster_name = "fruits"
  provider_name = "hcloud"
}

module "compute" {
  source = "upmaru/instellar/${local.provider_name}"
  version = "0.4.0"

  access_key   = var.aws_access_key
  secret_key   = var.aws_secret_key
  cluster_name = local.cluster_name
  node_size    = "cpx11"
  cluster_topology = [
    // replace name of node with anything you like
    // you can use 01, 02 also to keep it simple.
    {id = 1, name = "apple", size = "cpx11"},
    {id = 2, name = "watermelon", size = "cpx11"},
  ]
  storage_size = 30
  ssh_keys = [
    "zack-studio",
    "zack-one-eight"
  ]
}

variable "instellar_auth_token" {}

module "instellar" {
  source  = "upmaru/bootstrap/instellar"
  version = "0.3.1"

  auth_token      = var.instellar_auth_token
  cluster_name    = local.cluster_name
  region          = module.compute.region
  provider_name   = local.provider_name
  cluster_address = module.compute.cluster_address
  password_token  = module.compute.trust_token

  uplink_channel = "master"

  bootstrap_node = module.compute.bootstrap_node
  nodes          = module.compute.nodes
}
```

Create a file `.auto.tfvars` which should not be checked in with version control and add the credentials

```hcl
hcloud_token = "<your hcloud token>"
instellar_auth_key = "<retrieve from instellar dashboard>"
```

Simply run

```shell
terraform init
terraform plan
terraform apply
```

This will automatically form a cluster and add the resources to be managed by instellar.

## Changing Topology

The example above will form a cluster with 3 nodes, one node will be called the `bootrap-node` this node will be used to co-ordinate and orchestrate the setup. With this configuration you will get 2 more nodes `apple` and `watermelon`. You can name the node anything you want.

If you wish to add a node into the cluster you can modify the `cluster_topology` variable.

```diff
cluster_topology = [
  {id = 1, name = "apple", size = "cpx11"},
  {id = 2, name = "watermelon", size = "cpx11"},
+ {id = 3, name = "orange", size = "cpx11"}
]
```

Then run `terraform apply` it will automatically scale your cluster up and add `orange` to the cluster. You can also selectively remove a node from the cluster. Once you've bootstrapped your cluster do not change the `id` since it is used to compute assignments to subnets, if you don't want your nodes replaced don't change the `id`.

```diff
cluster_topology = [
  {id = 1, name = "apple", size = "cpx11"},
- {id = 2, name = "watermelon", size = "cpx11"},
  {id = 3, name = "orange", size = "cpx11"}
]
```

Running `terraform apply` will gracefully remove `watermelon` from the cluster.

### Instance Type

You can specify the type of instance to use by specifying the size in the `cluster_topology`.

```hcl
cluster_topology = [
  {id = 1, name = "apple", size = "cpx11"},
  {id = 2, name = "watermelon", size = "cpx11"},
  {id = 3, name = "orange", size = "cpx11"}
]
```

