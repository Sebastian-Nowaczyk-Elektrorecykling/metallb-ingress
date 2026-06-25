# Talos Argo CD GitOps platform

This repository is an app-of-apps GitOps baseline for a Talos Kubernetes cluster where Argo CD is already installed once. After the first `kubectl apply`, Argo CD takes over its own Helm release and manages the platform stack.

Included components:

- Argo CD, configured for Keycloak OIDC SSO
- MetalLB L2 with the requested `192.168.15.2-192.168.15.254` service pool
- ingress-nginx pinned to LoadBalancer VIP `192.168.15.1`
- cert-manager with a local lab CA issuer for HTTPS
- Rook/Ceph operator and Ceph cluster
- CloudNativePG operator
- Keycloak backed by a CloudNativePG PostgreSQL cluster
- Gitea in namespace `gitops-gitea`, backed by CloudNativePG and configured for Keycloak SSO
- oauth2-proxy in front of the Rook/Ceph dashboard, using Keycloak SSO

## Important safety checks

`192.168.15.1` must be unused on your LAN. If it is your router/default gateway, do not use it as a MetalLB VIP. Change the VIP before deploying.

The requested general MetalLB range `192.168.15.2-192.168.15.254` is very large. Make sure it does not overlap DHCP leases, Talos node IPs, your gateway, NAS, printers, or anything else. In most home networks you should shrink it to a small reserved block.

Rook is currently configured with:

```yaml
useAllNodes: true
useAllDevices: true
```

That can consume every empty, unformatted disk Rook considers available. Edit `infrastructure/rook-ceph-cluster/values.yaml` before first sync unless this is exactly what you want.

Plain Kubernetes Secret manifests are included with placeholders so the repo is complete. Run `scripts/generate-secrets.sh` before your first commit, then preferably encrypt `infrastructure/secrets/secrets.yaml` with SOPS/age or replace it with External Secrets, Sealed Secrets, or another secret-management flow.

## Public URLs

The default internal domain is `home.arpa`.

| Service | URL |
|---|---|
| Keycloak | `https://auth.home.arpa` |
| Argo CD | `https://argocd.home.arpa` |
| Gitea | `https://git.home.arpa` |
| Ceph dashboard SSO gate | `https://ceph.home.arpa` |

Set local DNS to point the wildcard at the ingress VIP:

```text
*.home.arpa.  A  192.168.15.1
```

## Repository layout

```text
bootstrap/
  root-app.yaml                         # Apply once to the existing Argo CD
argocd/apps/
  kustomization.yaml                     # App-of-apps root
  *.yaml                                # Child Argo CD Applications with sync waves
argocd/platform-config/
  repository-secrets.yaml                # Helm repo declarations for Argo CD
infrastructure/
  argocd/values.yaml                     # Argo CD chart values + Keycloak OIDC
  cert-manager/values.yaml               # cert-manager chart values
  certificates/                          # Local CA issuer + service certificates
  metallb/values.yaml                    # MetalLB chart values
  metallb-config/                        # IPAddressPools and L2Advertisement
  ingress-nginx/values.yaml              # ingress-nginx VIP config
  rook-ceph-operator/values.yaml         # Rook operator values
  rook-ceph-cluster/values.yaml          # Ceph cluster/storage classes/dashboard
  cloudnativepg/values.yaml              # CloudNativePG operator values
  secrets/                               # Namespaces and placeholder secrets
platform/
  keycloak-db/                           # CNPG Cluster for Keycloak
  keycloak/values.yaml                   # Keycloak chart values + realm/client config
  gitea-db/                              # CNPG Cluster for Gitea
  gitea/values.yaml                      # Gitea chart values + Keycloak OAuth
  ceph-dashboard-sso/values.yaml         # oauth2-proxy for Rook/Ceph dashboard
scripts/
  set-repo-url.sh
  set-domain.sh
  generate-secrets.sh
```

## Argo CD takeover caution

The repo installs the `argo-cd` Helm chart with release name `argocd` into the existing `argocd` namespace. This is safest when your bootstrap Argo CD was installed the same way. If your current Argo CD came from raw manifests or a different chart/release name, read `docs/argo-takeover.md` and inspect the app diff before syncing the takeover app.

## First-time use

```bash
unzip talos-argocd-platform-gitops.zip
cd talos-argocd-metallb-gitops

./scripts/set-repo-url.sh https://github.com/YOUR_USER/YOUR_REPO.git
./scripts/set-domain.sh apps.home.arpa
./scripts/generate-secrets.sh
```

Then review these files carefully:

```text
infrastructure/metallb-config/ip-address-pools.yaml
infrastructure/ingress-nginx/values.yaml
infrastructure/rook-ceph-cluster/values.yaml
infrastructure/secrets/secrets.yaml
platform/keycloak/values.yaml
platform/gitea/values.yaml
```

Commit and push:

```bash
git init
git add .
git commit -m "Bootstrap Talos GitOps platform"
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main
```

Apply the root app once:

```bash
kubectl apply -f bootstrap/root-app.yaml
```

Argo CD will then manage the rest.

## Sync order

The child Applications use Argo CD sync waves:

```text
-20  Argo CD repository/platform config
-10  Argo CD self-management
  0  MetalLB
 10  ingress-nginx
 15  cert-manager
 20  Rook/Ceph operator
 30  Rook/Ceph cluster and storage classes
 40  CloudNativePG operator
 50  namespaces and secrets
 55  local CA and TLS certificates
 60  Keycloak PostgreSQL cluster
 70  Keycloak
 80  Gitea PostgreSQL cluster
 90  Gitea
100  Ceph dashboard oauth2-proxy SSO gate
```

Some apps can be `Progressing` for a while on a first bootstrap. For example, Keycloak and Gitea may start before their CloudNativePG clusters are fully ready, then settle as PostgreSQL becomes available.

## SSO model

Keycloak creates realm `home`, groups, and OIDC clients using `keycloak-config-cli`.

Configured clients:

| Client | Redirect URI |
|---|---|
| `argocd` | `https://argocd.home.arpa/auth/callback` |
| `gitea` | `https://git.home.arpa/user/oauth2/keycloak/callback` |
| `ceph-dashboard` | `https://ceph.home.arpa/oauth2/callback` |

Configured groups:

```text
argocd-admins
argocd-readonly
gitea-admins
gitea-users
ceph-dashboard-users
```

Argo CD RBAC maps `argocd-admins` to `role:admin` and `argocd-readonly` to `role:readonly`. Gitea allows Keycloak-backed external registration and account linking; it also requests the `groups` claim and marks members of `gitea-admins` as Gitea administrators when Gitea applies the OAuth source settings. The Ceph dashboard is protected by oauth2-proxy before traffic reaches the dashboard; the dashboard still has its own internal Ceph admin account.

## TLS model

The repo includes cert-manager and a local CA called `homelab-ca`. This gives you HTTPS certificates for the default hosts, but browsers will not trust the CA until you install the generated root CA certificate on your devices.

After cert-manager syncs, export the root CA certificate with:

```bash
kubectl -n cert-manager get secret homelab-root-ca -o jsonpath='{.data.ca\.crt}' | base64 -d > homelab-root-ca.crt
```

For a cleaner long-term setup, replace `infrastructure/certificates/issuers.yaml` with an ACME DNS-01 `ClusterIssuer` and keep the existing `Certificate` resources.

## Health checks

```bash
kubectl -n argocd get applications.argoproj.io
kubectl -n ingress-nginx get svc ingress-nginx-controller
kubectl -n metallb-system get ipaddresspools,l2advertisements
kubectl -n rook-ceph get cephcluster,cephblockpool,cephfilesystem
kubectl -n cnpg-system get pods
kubectl -n keycloak get cluster,pods,ingress
kubectl -n gitops-gitea get cluster,pods,ingress
kubectl -n cert-manager get clusterissuer,certificates --all-namespaces
```

The ingress controller Service should show:

```text
EXTERNAL-IP   192.168.15.1
```
