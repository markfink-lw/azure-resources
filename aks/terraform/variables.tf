data "azurerm_resource_group" "cluster_rg" {
  name = "your_resource_group"
}

variable "cluster_name" {
  type    = string
  default = "your_cluster_name"
}

variable "dns_prefix" {
  type    = string
  default = "your-cluster-dns"
}

variable "kube_version" {
  type    = string
  default = "1.22.6"
}

variable "authorized_ip_ranges" {
  type    = list
  default = ["x.x.x.x/32"]
}
