# Argo CD takeover notes

The child app `argocd/apps/01-argocd.yaml` installs the `argo-cd` Helm chart with release name `argocd` into namespace `argocd`.

This is meant to converge an existing bootstrap Argo CD into GitOps control. It is safest when your current Argo CD was already installed from the same chart and release name.

Before enabling this against an existing manually-installed Argo CD, compare the rendered chart output with your current resources. The app has `prune: false` to reduce first-run risk, but Helm ownership labels and resource names still need to line up.

A conservative path is:

```bash
kubectl -n argocd get deploy,sts,svc,cm,secret
kubectl -n argocd get applications.argoproj.io
```

Then sync only `argocd-platform-config` and inspect the proposed `argocd` app diff in the UI before syncing the takeover app.

The local admin user remains enabled by default. After Keycloak SSO works, set this in `infrastructure/argocd/values.yaml`:

```yaml
configs:
  cm:
    admin.enabled: "false"
```
