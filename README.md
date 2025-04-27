# Introduction

# Talos Setup

1 Control Plane
3 Worker Nodes

Commands to run

```bash
talosctl get secrets -o talos-secrets.yaml

talosctl gen config --with-secrets <cluster-name> https://<control-plane-ip>:6443

# Apply for all control plane nodes
talosctl apply-config --insecure -n <control-plane-ip> --file controlplane.yaml

# This command only happens once in the clusters life. It is only done for the first control plane node. Do not apply for future control plane nodes, let alone worker nodes.
talosctl bootstrap -n <control-plane-ip> -e <control-plane-ip> --talosconfig ./talosconfig

# Apply for all worker nodes
talosctl apply-config --insecure -n <worker-ip> --file worker.yaml
```

# Flux Setup

```bash
export GITHUB_TOKEN=<GITHUB_TOKEN>

flux bootstrap github --token-auth --owner=jonathanruiz --repository=homelab --branch=main --path=./clusters/staging --personal

```

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
