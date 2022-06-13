@description('The name of the Managed Cluster resource.')
param resourceName string

@description('The location of AKS resource.')
param location string

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string

@description('Disk size (in GiB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The version of Kubernetes.')
param kubernetesVersion string = '1.7.7'

@description('Network plugin used for building Kubernetes network.')
@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string

@description('Boolean flag to turn on and off of RBAC.')
param enableRBAC bool = true

@description('Boolean flag to turn on and off of virtual machine scale sets')
param vmssNodePool bool = false

@description('Boolean flag to turn on and off of virtual machine scale sets')
param windowsProfile bool = false

@description('Enable private network access to the Kubernetes cluster.')
param enablePrivateCluster bool = false

@description('Boolean flag to turn on and off http application routing.')
param authorizedIPRanges array

@description('Boolean flag to turn on and off http application routing.')
param enableHttpApplicationRouting bool = true

@description('Boolean flag to turn on and off Azure Policy addon.')
param enableAzurePolicy bool = false

@description('Boolean flag to turn on and off secret store CSI driver.')
param enableSecretStoreCSIDriver bool = false

resource resourceName_resource 'Microsoft.ContainerService/managedClusters@2021-07-01' = {
  location: location
  name: resourceName
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: enableRBAC
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: 1
        enableAutoScaling: true
        minCount: 1
        maxCount: 2
        vmSize: 'Standard_B2ms'
        osType: 'Linux'
        storageProfile: 'ManagedDisks'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 110
        availabilityZones: []
        nodeTaints: []
        enableNodePublicIP: false
        tags: {}
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: networkPlugin
    }
    apiServerAccessProfile: {
      authorizedIPRanges: authorizedIPRanges
      enablePrivateCluster: enablePrivateCluster
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: enableHttpApplicationRouting
      }
      azurepolicy: {
        enabled: enableAzurePolicy
      }
      azureKeyvaultSecretsProvider: {
        enabled: enableSecretStoreCSIDriver
      }
    }
  }
  tags: {
    KubernetesCluster: resourceName
  }
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: []
}

output controlPlaneFQDN string = resourceName_resource.properties.fqdn