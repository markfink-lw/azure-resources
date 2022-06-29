For full details on the Lacework Data Collector for Windows:  <ADD_PUBLIC_URL_WHEN_AVAILABLE>

Ask your Lacework SE for the latest URL for the LWDataCollector.msi installer, which is needed for all Windows deployment methods in this repo.  Also, all Windows deployment methods (in this repo) depend on the `Install-LWCollector.ps1` script you see in this directory.  This script needs to be hosted where the target Azure VMs can download it via a URL (which can be this repo if this version of the script is suitable).  There is nothing sensitive in the script; you can host it where it is most convenient.

`azurerm` contains ARM templates in JSON and Bicep formats for deploying the Lacework Data Collector onto Azure Windows VMs. `terraform` contains a Terraform template for the same purpose.  Go into each directory for details.

`Install-LWCollector.ps1` can be run on any Windows host (in any environment).  Read the comments in the script for details.  For optimal performance, we recommend that you exclude the Data Collector from scanning with your AV or EDR product.  The script can configure this exclusion for Defender (it defaults to *not* configuring it).  If you use another AV/EDR product, then you can customize the script to suit you.

</br>

You can also download and run `Install-LWCollector.ps1` on existing Azure Windows VMs using PowerShell and Azure CLI commands, without using ARM or Terraform templates, in which case you can write PowerShell and/or bash scripts around these commands.

`Deploy-LW-Win.ps1` is an example of a PowerShell script that deploys the Collector in batch on many VMs using the PowerShell Az modules (you must have those modules installed).  It should work well in its current form; however, you should read the comments in the script to understand exactly how it works and possibly modify it to suit your needs.

Lastly, the following is an Azure CLI command for installing the Collector that we can write a bash script around, which is on our to-do list for this repo.

AZURE CLI:
```
az vm extension set \
  -g <resource_group> \
  --vm-name <target_vm_name> \
  -n customScriptExtension \
  --publisher Microsoft.Compute \
  --extension-instance-name LaceworkDC \
  --protected-settings '{"FileUris": "https://raw.githubusercontent.com/markfink-lw/azure-resources/master/windows/Install-LWCollector.ps1", "commandToExecute": "powershell -File Install-LWCollector.ps1 -Token <lacework_token> -Endpoint api.lacework.net -MsiInstaller https://path/to/LWDataCollector.msi [ -Defender ]"}'
```
