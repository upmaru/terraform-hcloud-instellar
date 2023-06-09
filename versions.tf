terraform {
  required_version = ">= 1.0.0"

  required_providers {
    ssh = {
      source = "loafoe/ssh"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.38"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}