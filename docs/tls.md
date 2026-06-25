# TLS

This repo installs cert-manager and bootstraps a local CA:

```text
ClusterIssuer/homelab-selfsigned
Certificate/homelab-root-ca
ClusterIssuer/homelab-ca
```

It then creates TLS certificates for:

```text
argocd.home.arpa
keycloak: auth.home.arpa
git.home.arpa
ceph.home.arpa
```

Export the root CA after the certificates app has synced:

```bash
kubectl -n cert-manager get secret homelab-root-ca -o jsonpath='{.data.ca\.crt}' | base64 -d > homelab-root-ca.crt
```

Install that CA into your desktop/mobile trust store if you want browsers to trust the internal HTTPS endpoints.

For a production-like homelab, replace the local CA with ACME DNS-01. Keep the `Certificate` resources and replace only the `issuerRef` and issuer manifests.
