variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of your cluster"
}

variable "cluster_size" {
  description = "How big do you want your cluster to be 1, 3, 5 or more."
  default     = 1
}

variable "image" {
  description = "Image type of choice default is Ubuntu 22.04"
  default     = "ubuntu-22.04"
}

variable "region" {
  description = "Region of your cluster"
  default     = "eu-central"
}

variable "location" {
  description = "Location of your server"
  default     = "fsn1"
}

variable "bastion_size" {
  description = "Size of the bastion instance defaults to Basic 512MB instance https://slugs.do-api.dev/"
  default     = "cx11"
}

variable "node_size" {
  description = "Type of server you want to provision"
  default     = "cpx11"
}

variable "subnet_ip_range" {
  description = "Subnet ip range"
  ip_range    = "10.0.1.0/24"
}

variable "ssh_keys" {
  type        = list(string)
  description = "List of ssh key names"
  default     = []
}