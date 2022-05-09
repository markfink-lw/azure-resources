This is an example Terraform template for installing the Lacework Data Collector onto an Azure Linux VM.  The template uses the CustomScript extension for Linux to download and install a bash script that installs the Collector.  This script is discussed in the README for the linux folder (parent to this folder).

`variables.tf` provides one parameter for the installer: the Lacework endpoint, which can be either api.lacework.net or api.fra.lacework.net.  It defaults to api.lacework.net.

In `main.tf`, scroll down to the bottom where we add the `azurerm_virtual_machine_extension` resource.  Here we use the CustomScript extension to download and run the bash script.  `FileUris` should point to the URL for the bash script.
