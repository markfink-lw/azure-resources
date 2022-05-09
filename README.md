This repo provides templates and scripts for deploying the Lacework Data Collector onto VMs hosted in Azure.

Four deployment methods are provided at this time:
- Azure ARM / Bicep templates
- Terraform
- PowerShell Az module commands (in a PowerShell script)
- Azure CLI commands (in a bash script)

You will find examples of each that you can tailor as you need.  They all leverage CustomScriptExtension for Windows and CustomScript for Linux (which are two extensions that do the same thing per OS).

Here are links to documentation for these extensions:

https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows

https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux

</br>

Go into the directories for more details.  The READMEs at each directory level build on each other.
