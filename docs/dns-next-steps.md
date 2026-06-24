# DNS next steps

After ingress-nginx has the VIP `192.168.15.1`, configure local DNS so LAN clients and cluster pods can resolve your application names.

Common simple setup:

```text
*.apps.example.lan.  A  192.168.15.1
```

Then create app Ingress resources with hosts like:

```text
auth.apps.example.lan
argocd.apps.example.lan
grafana.apps.example.lan
```

For Keycloak/OIDC, make the issuer URL the same URL that browsers and in-cluster clients use, for example:

```text
https://auth.apps.example.lan/realms/home
```
