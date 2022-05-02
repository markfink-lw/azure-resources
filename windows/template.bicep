param location string = resourceGroup().location
param networkInterfaceName string
param networkSecurityGroupName string
param virtualNetworkName string
param publicIpAddressName string
param virtualMachineName string
param virtualMachineComputerName string
param virtualMachineSize string
param adminUsername string

@secure()
param adminPassword string

@minLength(56)
@maxLength(56)
@secure()
param laceworkToken string
param laceworkInstaller string
param laceworkDefender bool
param laceworkEndpoint string

var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/default'
var scriptCommand = 'powershell -File Install-LWCollector.ps1 -token ${laceworkToken} -endpoint ${laceworkEndpoint} -installer ${laceworkInstaller}'

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

resource publicIpAddress 'Microsoft.Network/publicIpAddresses@2019-02-01' = {
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
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-smalldisk-g2'
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
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: 'AutomaticByOS'
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

resource lacework_dc 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = {
  parent: virtualMachine
  name: 'install-lacework-dc'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    protectedSettings: {
      commandToExecute: (laceworkDefender ? '${scriptCommand} -defender' : scriptCommand)
      fileUris: [
        'https://raw.githubusercontent.com/markfink-lw/azure-resources/master/windows/Install-LWCollector.ps1'
      ]
    }
  }
}
