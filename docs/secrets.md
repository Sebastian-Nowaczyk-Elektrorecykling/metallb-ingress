# Secrets

This repo includes plain Kubernetes Secret manifests with `CHANGE_ME_*` placeholders so the structure is complete and easy to test.

Run once before your first commit:

```bash
./scripts/generate-secrets.sh
```

Then strongly consider encrypting secrets before pushing to any Git server. Common options:

- SOPS with age
- Sealed Secrets
- External Secrets Operator backed by a password manager or vault

Secrets currently defined in `infrastructure/secrets/secrets.yaml`:

```text
keycloak-admin
keycloak-db-app
gitea-db-app
gitea-admin
gitea-oidc
ceph-dashboard-oauth2-proxy
```

The same generated OIDC client secret values must match in both Keycloak's realm config and the consuming applications. The helper script updates all matching placeholders across the repo.
