# argocd

ArgoCD GitOps configuration for continuous deployment to EKS.

## Structure

```
argocd/
└── application.yml    # ArgoCD Application manifest
```

## How it works

ArgoCD watches the `k8s/` folder in this repository. When any manifest changes (including image SHA tag updates from the CI pipeline), ArgoCD automatically syncs the changes to the EKS cluster.

```
CI Pipeline pushes new image SHA to k8s/backend/deployment.yml
                    │
                    ▼
        ArgoCD detects Git change
                    │
                    ▼
        ArgoCD applies updated manifest to EKS
                    │
                    ▼
        Rolling update — zero downtime deployment
```

## Configuration

The ArgoCD application is configured with:
- **Auto-sync** — automatically deploys on Git changes
- **Self-heal** — reverts manual kubectl changes back to Git state
- **Prune** — removes resources deleted from Git
- **Recurse** — watches all subdirectories under `k8s/`

## Access ArgoCD UI

```bash
# Port-forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open https://localhost:8080
# Get admin password:
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```
