# SSO wiring

Keycloak is the identity provider for the stack.

Realm:

```text
home
```

Issuer:

```text
https://auth.home.arpa/realms/home
```

OIDC clients:

```text
argocd
  redirect: https://argocd.home.arpa/auth/callback

gitea
  redirect: https://git.home.arpa/user/oauth2/keycloak/callback

ceph-dashboard
  redirect: https://ceph.home.arpa/oauth2/callback
```

Groups created by Keycloak:

```text
argocd-admins
argocd-readonly
gitea-admins
gitea-users
ceph-dashboard-users
```

Argo CD consumes the `groups` claim for RBAC. Gitea registers an OpenID Connect auth source using the chart's `gitea.oauth` values, requests the `groups` claim, and maps `gitea-admins` to administrator privileges. The Ceph dashboard is protected by oauth2-proxy, which authenticates against Keycloak before proxying to the internal Rook/Ceph dashboard service.

After first login, create or assign users in Keycloak to the groups you want. You can keep Argo CD's local admin user enabled until SSO is verified, then set `configs.cm.admin.enabled: "false"` in `infrastructure/argocd/values.yaml`.
