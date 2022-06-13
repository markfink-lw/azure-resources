This folder provides templates and instructions for implementing the Lacework Data Collector with AKS clusters and storing/accessing the Data Collector configuration in Key Vault.  If you do not require Key Vault, then you can follow the standard instructions for deploying the Data Collector in Kubernetes at https://docs.lacework.com/deploy-on-kubernetes.

We use the Azure Key Vault Provider for Secrets Store CSI Driver.  Documentation is here (click the link and have it ready as we go through this):
https://azure.github.io/secrets-store-csi-driver-provider-azure/docs/getting-started/usage/

First, you need to enable the CSI driver in your cluster.  For an existing cluster, you can install it via Helm or Kubernetes manifest per the site above.  Azure provides the option to enable it when creating your cluster via a checkbox in the Portal or as an option in an ARM or Terraform template.  Look at the templates provided in this folder as examples.  Look for:
- `azureKeyvaultSecretsProvider` in the ARM template
- `key_vault_secrets_provider` in the Terraform template

Next, create a secret in Key Vault that stores the Data Collector configuration.  You can do this in the Portal or via CLI as below.  Here we use `laceworkK8sConfig` as the name of the secret.
AZURE CLI:
```
az keyvault secret set --vault-name YOUR_KEY_VAULT --name laceworkK8sConfig --value '{"tokens":{"AccessToken":"YOUR_TOKEN"}, "tags":{"KubernetesCluster":"YOUR_CLUSTER_NAME","Env":"k8s"}, "serverurl":"https://api.lacework.net"}'
```

POWERSHELL:
```
$secret = ConvertTo-SecureString -String '{"tokens":{"AccessToken":"YOUR_TOKEN"}, "tags":{"KubernetesCluster":"YOUR_CLUSTER_NAME","Env":"k8s"}, "serverurl":"https://api.lacework.net"}' -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName YOUR_KEY_VAULT -Name laceworkK8sConfig -SecretValue $secret
```

Now we follow the instructions for using the CSI driver in the link above, step-by-step.  The next step is to create a SecretProviderClass object in your cluster for your Key Vault secret (the Data Collector configuration).  Look at `azureSecretProviderClass.yaml` in this folder as an example; it references the `laceworkK8sConfig` secret created above.  Note that `objectAlias: config.json` in the yaml file is important; the Data Collector expects the configuration file to be named `config.json`; without this option, the file name will be the secret name and the Data Collector will fail.  You can review all the options for the SecretProviderClass at the link above.

The next step entitled "Provide Identity to Access Key Vault" is essential and will vary based on your situation.  In short, you must configure permission to allow your AKS cluster to access your Key Vault, and there are five ways listed to do this, none of which are easily automated.  In our testing, we followed the link and instructions for System-assigned Managed Identity.  <i>This affects the configuration for the SecretProviderClass.</i>

Next, we update the Data Collector daemonset manifest to use the Key Vault secret.  Start with the `lacework-k8s.yaml` file provided in your Lacework account (Settings->Agents, create a new token or click the menu on the right for an existing token, select Install, Kubernetes Orchestration, Download).  The default manifest uses a configmap to store the config; we will replace this.

You'll find the configmap configured as a volume in the standard manifest, as follows:
```
        - name: cfgmap
          configMap:
            defaultMode: 0640
            name: lacework-config
            items:
            - key: config.json
              path: config.json
```

Replace those lines with these lines that use the SecretProviderClass.  See `lacework-k8s-csi.yaml` as an example.
```
        - name: config
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "lacework-config"
```

Also, because we change the name of the volume, update the volumeMounts section as follows:
```
        volumeMounts:
          - name: config
            mountPath: /var/lib/lacework/config
```

Deploy and verify operation.
