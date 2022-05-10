`template.json` and `template.bicep` are example ARM templates for installing the Lacework Data Collector onto a Linux VM (Microsoft is moving away from JSON to Bicep).  The templates use the CustomScript extension for Linux to download and install a bash script that installs the Collector.  This script is discussed in the README for the linux folder (parent to this folder).

`parameters.json` provides one parameter for the installer: the Lacework endpoint, which can be either api.lacework.net or api.fra.lacework.net.  It defaults to api.lacework.net.

In the template files, scroll down to the bottom where we add the `Microsoft.Compute/virtualMachines/extensions` resource.  Here we use the CustomScript extension to download and run the bash script.  `FileUris` should point to the URL for the bash script.  Note that this extension is named similarly to the Windows CustomScriptExtension, but it is a different extension.

The following are commands you can use to deploy the ARM template (these are standard commands). We assume you already have a resource group created for your deployment.

POWERSHELL:
```
New-AzResourceGroupDeployment -Name <deployment_name> -ResourceGroupName <resource_group> -TemplateFile .\template.<json | bicep> -TemplateParameterFile .\parameters.json
```

AZURE CLI:
```
az deployment group create -n <deployment_name> -g <resource_group> -f ./template.<json | bicep> -p @./parameters.json
```
