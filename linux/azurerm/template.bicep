param location string = resourceGroup().location
param networkInterfaceName string
param networkSecurityGroupName string
param virtualNetworkName string
param publicIpAddressName string
param virtualMachineName string
param virtualMachineComputerName string
param osDiskType string
param virtualMachineSize string
param adminUsername string
param sshKey string
param laceworkEndpoint string

var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/default'
var sshKeyId = resourceId(resourceGroup().name, 'Microsoft.Compute/sshPublicKeys', sshKey)

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddress.id
            properties: {
              deleteOption: 'Delete'
            }
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
}

resource publicIpAddress 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '82gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineComputerName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: reference(sshKeyId, '2019-12-01').publicKey
              path: '/home/${adminUsername}/.ssh/authorized_keys'
            }
          ]
        }
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource lacework_dc 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  parent: virtualMachine
  name: 'install-lacework-dc'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    protectedSettings: {
      commandToExecute: './install.sh -U https://${laceworkEndpoint}'
      fileUris: [
        'https://path/to/install.sh'
      ]
    }
  }
}
