For full details on the Lacework Data Collector for Linux: https://docs.lacework.com/category/lacework-for-workload-security

All Linux deployment methods in this repo depend on the install.sh bash script you can download in your Lacework account:
- Go into Settings->Agents
- Either create a new token or select an existing token
- Click the ellipsis menu on the far right of the token and select Install 
- Select "Lacework Script" and you will see an option to download the script.

The script needs to be hosted where the target Azure VMs can download it via a URL.  The script contains your Lacework token so you should put it somewhere secure, say in a private Azure Storage container.

`azurerm` contains ARM templates in JSON and Bicep formats for deploying the Lacework Data Collector onto Azure Linux VMs. `terraform` contains a Terraform template for the same purpose.  Go into each directory for details.

</br>

You can also download and run the install.sh script on existing Azure Linux VMs using PowerShell and Azure CLI commands, without using ARM or Terraform templates, in which case you can write PowerShell and/or bash scripts around these commands.

`Deploy-LW-Linux.ps1` is an example of a PowerShell script that deploys the Collector in batch on many VMs using the PowerShell Az modules (you must have those modules installed).  It should work well in its current form; however, you should read the comments in the script to understand exactly how it works and possibly modify it to suit your needs.

Lastly, the following is an Azure CLI command for installing the Collector that we can write a bash script around, which is on our to-do list for this repo.

AZURE CLI:
```
az vm extension set \
  -g <resource_group> \
  --vm-name <target_vm_name> \
  -n customScript \
  --publisher Microsoft.Azure.Extensions \
  --extension-instance-name LaceworkDC \
  --protected-settings '{"fileUris": ["https://path/to/install.sh"],"commandToExecute": "./install.sh -U api.lacework.net"}'
```
