`template.json` and `template.bicep` are example ARM templates for installing the Lacework Data Collector onto an Azure Windows VM (Microsoft is moving away from JSON to Bicep).  The templates use the CustomScriptExtension for Windows to download and install the `Install-LWCollector.ps1` script.  This script is discussed in the README for the windows folder (parent to this folder).

See the Lacework configuration parameters at the bottom of `parameters.json`.  These correspond to the parameters used in `Install-LWCollector.ps1`.  It is good practice to store your Lacework token securely in Azure Key Vault; `parameters.json` shows how to reference a token stored in Key Vault.  The MSI installer URL also needs to be updated; ask your Lacework SE for the latest URL.

Next, in the template files, look at the `parameters` and `variables` sections starting at the top.  `variables` defines the script command used to install the Data Collector.  Scroll down to the bottom where we add the `Microsoft.Compute/virtualMachines/extensions` resource.  Here we use the CustomScriptExtension to download and run `Install-LWCollector.ps1` with the optional `defender` flag.  `FileUris` should point to the URL for `Install-LWCollector.ps1`.

The following are commands you can use to deploy the ARM template (these are standard commands). We assume you already have a resource group created for your deployment.

POWERSHELL:
```
New-AzResourceGroupDeployment -Name <deployment_name> -ResourceGroupName <resource_group> -TemplateFile .\windows\template.<json | bicep> -TemplateParameterFile .\windows\parameters.json
```

AZURE CLI:
```
az deployment group create -n <deployment_name> -g <resource_group> -f ./windows/template.<json | bicep> -p @./windows/parameters.json
```
