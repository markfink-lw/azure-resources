See documentation for full details on the Windows Data Collector:  <ADD_PUBLIC_URL_WHEN_AVAILABLE>

The `Install-LWCollector.ps1` script can be run on any Windows host.  Read the comments in the script for details.  For optimal performance, we recommend that you exclude the Data Collector from scanning with your AV or EDR product.  The script can optionally configure this exclusion for Defender (it defaults to not configuring it).  If you use another AV product, then you can customize the script to suit you.

`template.json` and `template.bicep` are example ARM templates for installing the agent onto a Windows VM (Microsoft is moving away from JSON to Bicep).  The templates use the CustomScriptExtension for Windows to download and install the `Install-LWCollector.ps1` script.  This script needs to be posted where the CustomScriptExtension can download it via a URL.

See the Lacework parameters at the bottom of `parameters.json`, which correspond to the parameters used in the PS script.  It is good practice to store your Lacework token securely in Azure Key Vault; `parameters.json` shows how to reference a token stored in Key Vault.  The MSI installer URL also needs to be updated.  We will update that URL when we make it public (it is currently beta).  Ask your Lacework SE for the latest URL.

Next, in the template files, look at the `parameters` and `variables` sections starting at the top.  `variables` defines the script command used to install the Data Collector.  Scroll down to the bottom where we add the `Microsoft.Compute/virtualMachines/extensions` resource.  Here we use a CustomScriptExtension to download and run the PS script with the optional `defender` flag.  `FileUris` should point to the URL for the PS script.

The following are commands you can use to deploy the ARM template (these are standard commands):

POWERSHELL:
```
New-AzResourceGroupDeployment -Name <deployment_name> -ResourceGroupName <resource_group> -TemplateFile .\windows\template.<json | bicep> -TemplateParameterFile .\windows\parameters.json
```

AZURE CLI:
```
az deployment group create -n <deployment_name> -g <resource_group> -f ./windows/template.<json | bicep> -p @./windows/parameters.json
```

<br/>

You can also download and run the PS script to an existing Azure Windows VM using PowerShell and Azure CLI commands, without using an ARM template, in which case you could write a PowerShell or bash script around these commands.

POWERSHELL: <br/>
```
Set-AzVMCustomScriptExtension `
    -ResourceGroupName <resource_group> `
    -VMName <target_vm_name> `
    -Name install-lacework-dc `
    -FileUri "https://raw.githubusercontent.com/markfink-lw/azure-resources/master/windows/Install-LWCollector.ps1" `
    -Run 'Install-LWCollector.ps1 -token <lacework_token> -endpoint api.lacework.net -installer https://path/to/LWDataCollector.msi [ -defender ]' `
    -SecureExecution
```

AZURE CLI:
```
az vm extension set \
  -g <resource_group> \
  --vm-name <target_vm_name> \
  -n customScriptExtension \
  --publisher Microsoft.Compute \
  --extension-instance-name install-lacework-dc \
  --protected-settings '{"FileUris": "https://raw.githubusercontent.com/markfink-lw/azure-resources/master/windows/Install-LWCollector.ps1", "commandToExecute": "powershell -File Install-LWCollector.ps1 -token <lacework_token> -endpoint api.lacework.net -installer https://path/to/LWDataCollector.msi [ -defender ]"}'
```
