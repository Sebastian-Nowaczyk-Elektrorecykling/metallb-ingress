# Talos Argo CD GitOps: MetalLB + ingress VIP

This repository bootstraps MetalLB through Argo CD and exposes an ingress controller with the requested LoadBalancer VIP:

- MetalLB chart: `metallb/metallb` `0.16.1`
- MetalLB mode: Layer 2, native backend
- Main service IP pool: `192.168.15.2-192.168.15.254`
- Dedicated ingress VIP pool: `192.168.15.1/32`, `autoAssign: false`
- ingress-nginx controller Service requests `192.168.15.1`

> Important: `192.168.15.1` must be unused on your LAN. If it is your router/default gateway, do **not** use it as a MetalLB VIP. Change `METALLB_INGRESS_VIP` to a free IP outside DHCP instead.
>
> Also verify the main pool `192.168.15.2-192.168.15.254` does not overlap DHCP leases, Talos node IPs, router IPs, NAS/printer IPs, or anything else on the LAN. In most networks you should shrink this range to a small reserved block, for example `192.168.15.240-192.168.15.250`.

## Repository layout

```text
bootstrap/
  root-app.yaml                       # Apply once to Argo CD
argocd/apps/
  kustomization.yaml                   # App-of-apps root
  metallb.yaml                         # MetalLB Helm chart + Git config as one Argo CD app
  ingress-nginx.yaml                   # ingress-nginx pinned to 192.168.15.1
infrastructure/metallb-config/
  ip-address-pools.yaml                # MetalLB IPAddressPools
  l2-advertisement.yaml                # MetalLB L2Advertisement
examples/loadbalancer-test/
  kustomization.yaml                   # Optional test workload using the general pool
scripts/
  set-repo-url.sh                      # Replaces the placeholder repo URL
```

## First-time use

1. Create a Git repo and push this content.
2. Replace the placeholder repo URL:

   ```bash
   ./scripts/set-repo-url.sh https://github.com/YOUR_USER/YOUR_REPO.git
   ```

3. Review the IPs in:

   ```text
   infrastructure/metallb-config/ip-address-pools.yaml
   argocd/apps/ingress-nginx.yaml
   ```

4. Commit and push.
5. Apply the root app once to the cluster where Argo CD already exists:

   ```bash
   kubectl apply -f bootstrap/root-app.yaml
   ```

Argo CD will then manage the rest.

## Expected result

After sync completes:

```bash
kubectl -n metallb-system get pods
kubectl -n metallb-system get ipaddresspools,l2advertisements
kubectl -n ingress-nginx get svc ingress-nginx-controller
```

The ingress controller Service should show:

```text
EXTERNAL-IP   192.168.15.1
```

Then point your local DNS wildcard to the VIP, for example:

```text
*.apps.example.lan.  A  192.168.15.1
```

Your application `Ingress` objects can then use names such as:

```text
auth.apps.example.lan
argocd.apps.example.lan
grafana.apps.example.lan
```

## Why there are two MetalLB pools

The requested general pool is:

```text
192.168.15.2-192.168.15.254
```

The requested ingress VIP is:

```text
192.168.15.1
```

Because `192.168.15.1` is outside the requested general pool, this repo defines a second `/32` pool just for the ingress VIP. It has `autoAssign: false`, so MetalLB will not hand out `192.168.15.1` accidentally to random `LoadBalancer` Services. Only a Service that explicitly requests it gets that VIP.

## Optional test

To test the general `192.168.15.2-192.168.15.254` pool without touching ingress, apply:

```bash
kubectl apply -k examples/loadbalancer-test
kubectl -n lb-test get svc
```

The test Service should receive an IP from the general pool, not `192.168.15.1`.

Remove it with:

```bash
kubectl delete -k examples/loadbalancer-test
```
