# k8s

Kubernetes manifests for deploying the DevOps Bank App to EKS (or any Kubernetes cluster).

## Structure

```
k8s/
├── namespace.yml              # devops-bank namespace
├── configmap.yml              # Non-secret config (DB host, port, etc.)
├── sealed-secret.yml          # Encrypted secrets (safe to commit)
├── backend/
│   ├── deployment.yml         # Backend deployment (image auto-updated by CI)
│   └── service.yml            # ClusterIP service
├── database/
│   ├── deployment.yml         # PostgreSQL deployment
│   ├── service.yml            # ClusterIP service
│   ├── pvc.yml                # Persistent volume claim (gp2, 5Gi)
│   └── initdb-configmap.yml   # Database init SQL
├── frontend/
│   ├── deployment.yml         # Frontend deployment (image auto-updated by CI)
│   └── service.yml            # LoadBalancer service (external access)
└── monitoring/
    └── namespace.yml          # monitoring namespace
```

## Secrets Management

Secrets are managed with **Bitnami Sealed Secrets**. The `sealed-secret.yml` file contains encrypted values that can only be decrypted by the Sealed Secrets controller running in the cluster.

**To create/update the sealed secret:**

```bash
# Create the plain secret file (never commit this)
cat > /tmp/secret.yml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: devops-bank-secret
  namespace: devops-bank
type: Opaque
stringData:
  DB_PASSWORD: "your-password"
  DB_USER: "bankuser"
  JWT_SECRET: "your-jwt-secret"
