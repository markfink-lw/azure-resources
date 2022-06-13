provider "azurerm" {
  features {}
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                             = var.cluster_name
  location                         = data.azurerm_resource_group.cluster_rg.location
  resource_group_name              = data.azurerm_resource_group.cluster_rg.name
  dns_prefix                       = var.dns_prefix
  kubernetes_version               = var.kube_version
  api_server_authorized_ip_ranges  = var.authorized_ip_ranges
  http_application_routing_enabled = false
  azure_policy_enabled             = false

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  default_node_pool {
    name                = "agentpool"
    vm_size             = "Standard_B2ms"
    enable_auto_scaling = true
    node_count          = 1
    min_count           = 1
    max_count           = 2
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    KubernetesCluster = var.cluster_name
  }
}
