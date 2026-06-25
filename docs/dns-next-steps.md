# DNS next steps

After ingress-nginx has the VIP `192.168.15.1`, configure local DNS so LAN clients and cluster pods can resolve the same application names.

Default wildcard:

```text
*.home.arpa.  A  192.168.15.1
```

Default service names:

```text
auth.home.arpa     # Keycloak issuer
argocd.home.arpa   # Argo CD
git.home.arpa      # gitops-gitea
ceph.home.arpa     # oauth2-proxy gate to the Rook/Ceph dashboard
```

For OIDC/SSO, the issuer URL must be the same URL that browsers and in-cluster clients use:

```text
https://auth.home.arpa/realms/home
```

Pods must also be able to resolve the public names. The simplest path is to make Kubernetes CoreDNS forward normal DNS to your LAN resolver, and make that resolver authoritative for `home.arpa` or able to answer the wildcard record.
