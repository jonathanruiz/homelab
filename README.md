# Homelab

A GitOps homelab running on Talos Linux Kubernetes (1 control plane, 3 workers) managed by Flux CD, alongside 3 Debian Docker VMs on a Proxmox host.

---

# Proxmox Setup

## 1. Install Proxmox VE

Install Proxmox VE on the Protectli Vault. Set the hostname to `pve001` and FQDN to `pve001.local.<DOMAIN_NAME>.com`.

## 2. Post-install script

After install, run the community post-install script to disable the enterprise repo, enable no-subscription, and apply recommended settings:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"
```

## 3. Enable Snippets on local storage

In Proxmox UI: **Datacenter → Storage → local → Edit → Content → check Snippets**

## 4. Create API token

1. **Datacenter → Permissions → API Tokens → Add**
   - User: `root@pam`
   - Token ID: `terraform`
   - Privilege Separation: disabled
2. Copy the token secret — it is only shown once
3. Store in 1Password: `op://VAULT/SECRET_NAME/SECRET_FIELD`
   - Value format: `root@pam!terraform=<uuid>`

## 5. Add SSH key to Proxmox

```bash
op read "op://VAULT/SSH_NAME/SSH_PUBLIC_KEY" | ssh root@IP_ADDRESS "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
ssh-add ~/.ssh/id_ed25519
```

## 6. Download Debian cloud image

In Proxmox UI: **local → ISO Images → Download from URL**

Use the Debian genericcloud qcow2 URL from `cloud.debian.org`. The `proxmox_download_file` Terraform resource requires `root@pam` — if it fails with a 403 on the URL metadata check, download via the UI instead and reference the file directly via `var.vm_base_image`.

## 7. Provision VMs with Terraform

```bash
cd proxmox/terraform

# Copy and fill in values
cp terraform.tfvars.example terraform.tfvars
cp .env.terraform.example .env.terraform

# Initialize
op run --env-file=.env.terraform -- terraform init

# Preview
op run --env-file=.env.terraform -- terraform plan

# Apply
op run --env-file=.env.terraform -- terraform apply
```

Secrets (`proxmox_api_token`, `ssh_public_key`) are injected at runtime via 1Password — never stored on disk.

## 8. SSH into VMs

```bash
ssh deploy@<vm_media_ip>    # vmdkr001 — Media stack
ssh deploy@<vm_home_ai_ip>  # vmdkr002 — Home/AI stack
ssh deploy@<vm_network_ip>  # vmdkr003 — Network stack
```

---

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
flux bootstrap github --token-auth --owner=jonathanruiz --repository=homelab --branch=main --path=./clusters/production --personal

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

This needs to be deployed before the Flux bootstrap command is run, otherwise the `external-secrets` controller will not be able to access the Azure Key Vault.

```
kubectl apply -f azure-secret-creds.yaml
```
