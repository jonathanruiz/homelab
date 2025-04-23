# Introduction

# Secret

To get things rolling, I needed to manually create a secret in the `external-secrets` namespace so that Azure Key Vault can be accessed by the `external-secrets` service account.

```yaml
apiVersion: v1
kind: Secret
metadata:
name: azure-secret-creds
namespace: external-secrets
type: Opaque
stringData:
  clientId: "CLIENT_ID"
  clientSecret: "CLIENT_SECRET"
  tenantId: "TENANT_ID"
  akvUrl: "https://KEY_VAULT_NAME.vault.azure.net/"
```
