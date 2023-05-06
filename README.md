# Terraform Module for Hetzner Cloud

This module automates setting up LXD and clustering for using with [instellar.app](https://instellar.app)

## Components

Here are the components that make up the cluster.

### Bastion

This node is the only node which is accessible via port 22 from the outside.

### Bootstrap Node

This is the node that we use to bootstrap the LXD cluster.

### Nodes

These are the worker nodes that joined the cluster.