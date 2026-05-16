# Homelab

A GitOps homelab running on Talos Linux Kubernetes (1 control plane, 3 workers) managed by Flux CD, alongside 3 Debian Docker VMs on a Proxmox host.

---

# Proxmox Setup

## 1. Install Proxmox VE

Install Proxmox VE on the Protectli Vault. Set the hostname to `<HOST_NAME>` and FQDN to `<HOST_NAME>.local.<DOMAIN_NAME>.com`.

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

1 Control Plane, 3 Worker Nodes. Run all commands from `talos/production/`.

```bash
# Generate secrets (only once per cluster lifetime)
talosctl gen secrets -o talos-secrets.yaml

# Generate machine configs from secrets
talosctl gen config --with-secrets talos-secrets.yaml <cluster-name> https://<control-plane-ip>:6443

# Apply config to all control plane nodes
talosctl apply-config --insecure -n <control-plane-ip> --file controlplane.yaml

# Bootstrap the cluster — only run once, only on the first control plane node
talosctl bootstrap -n <control-plane-ip> -e <control-plane-ip> --talosconfig ./talosconfig

# Apply config to all worker nodes
talosctl apply-config --insecure -n <worker-ip> --file worker.yaml

# Retrieve kubeconfig
talosctl kubeconfig --talosconfig ./talosconfig -n <control-plane-ip> ../kubeconfig
```

---

# Cilium Bootstrap

Cilium must be installed before Flux, since it is the CNI — without it no pods can run and Flux cannot start. The bootstrap manifest is generated from the same Helm values used by the `HelmRelease` in `infrastructure/controllers/cilium/`. Once Flux is running it takes over managing Cilium.

```bash
# Add the Cilium Helm repo
helm repo add cilium https://helm.cilium.io/
helm repo update

# Render the bootstrap manifest (run from repo root)
helm template cilium cilium/cilium \
  --version 1.19.3 \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=localhost \
  --set k8sServicePort=7445 \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set ipam.mode=kubernetes \
  --set operator.replicas=1 \
  --set l2announcements.enabled=true \
  --set externalIPs.enabled=true \
  --set securityContext.capabilities.ciliumAgent='{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}' \
  --set securityContext.capabilities.cleanCiliumState='{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}' \
  > talos/cilium-bootstrap.yaml

# Apply to the cluster
kubectl --kubeconfig=talos/kubeconfig apply -f talos/cilium-bootstrap.yaml
```

---

# Secret

Before running Flux bootstrap, manually create the Azure Key Vault credentials secret in the cluster. The `external-secrets` controller needs this to access Azure Key Vault — it cannot be managed by Flux itself since Flux depends on it.

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

```bash
kubectl --kubeconfig=talos/kubeconfig apply -f talos/production/akv-secret.yaml
```

---

# Flux Setup

```bash
export GITHUB_TOKEN=<GITHUB_TOKEN>
flux bootstrap github --token-auth --owner=jonathanruiz --repository=homelab --branch=main --path=./clusters/production --personal
```
