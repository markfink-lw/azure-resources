For full details on the Lacework Data Collector for Linux: https://docs.lacework.com/category/lacework-for-workload-security

`template.json` and `template.bicep` are example ARM templates for installing the Lacework Data Collector onto a Linux VM (Microsoft is moving away from JSON to Bicep).  The templates use the CustomScript extension for Linux to download and install a bash script that installs the Collector.  You can download the bash script in your Lacework account in Settings, Agents, either create a token or select an existing token, click the ellipsis menu on the far right of the token, and select Install.  Then select "Lacework Script" and you will see an option to download it.  This script needs to be posted where the CustomScript extension can download it via a URL.  The script contains your access token so you should put it somewhere secure, say in a private Azure Storage container.

`parameters.json` provides one parameter for the installer: the Lacework endpoint, which can be either api.lacework.net or api.fra.lacework.net.  It defaults to api.lacework.net.

In the template files, scroll down to the bottom where we add the `Microsoft.Compute/virtualMachines/extensions` resource.  Here we use the CustomScript extension to download and run the bash script.  `FileUris` should point to the URL for the bash script.  Note that this extension is named similarly to the Windows CustomScriptExtension, but it is a different extension.

The following are commands you can use to deploy the ARM template (these are standard commands):

POWERSHELL:
```
New-AzResourceGroupDeployment -Name <deployment_name> -ResourceGroupName <resource_group> -TemplateFile .\linux\template.<json | bicep> -TemplateParameterFile .\linux\parameters.json
```

AZURE CLI:
```
az deployment group create -n <deployment_name> -g <resource_group> -f ./linux/template.<json | bicep> -p @./linux/parameters.json
```

<br/>

You can also download and run the bash script to an existing Azure Linux VM using PowerShell and Azure CLI commands, without using an ARM template, in which case you could write a PowerShell or bash script around these commands.  Note the subtle differences between these commands and those used for Windows (these differences are tied to how Microsoft has implemented each).

POWERSHELL: <br/>
```
Set-AzVMExtension `
    -ResourceGroupName <resource_group> `
    -VMName <target_vm_name> `
    -Type "customScript" `
    -Publisher "Microsoft.Azure.Extensions" `
    -TypeHandlerVersion "2.1" `
    -Name "install-lacework-dc" `
    -ProtectedSettingString '{"fileUris": ["https://path/to/install.sh"],"commandToExecute": "./install.sh -U api.lacework.net"}'
```

AZURE CLI:
```
az vm extension set \
  -g <resource_group> \
  --vm-name <target_vm_name> \
  -n customScript \
  --publisher Microsoft.Azure.Extensions \
  --extension-instance-name install-lacework-dc \
  --protected-settings '{"fileUris": ["https://path/to/install.sh"],"commandToExecute": "./install.sh -U api.lacework.net"}'
```
