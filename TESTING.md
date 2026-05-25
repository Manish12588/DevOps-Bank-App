# 🧪 Testing & Validation Guide

This guide walks through validating the complete DevOps Bank App deployment end to end.

## Prerequisites

Before running these tests, ensure:
- AWS CLI configured (`aws configure`)
- kubectl installed
- Helm 3+ installed
- Repository cloned and on `main` branch
- All GitHub Secrets and Variables configured (see [README.md](README.md))

---

## Step 1 — Provision EKS Infrastructure

### Trigger

```
GitHub → Actions → Provision EKS Infrastructure → Run workflow → main
```

Expected duration: ~25 minutes

### Validate

```bash
# 1. Configure kubectl
aws eks update-kubeconfig \
  --region us-west-2 \
  --name devops-bank-eks

# 2. Check nodes are Ready
kubectl get nodes

# 3. Check EBS CSI driver
kubectl get pods -n kube-system | grep ebs

# 4. Check Sealed Secrets controller
kubectl get pods -n kube-system | grep sealed

# 5. Check ArgoCD pods
kubectl get pods -n argocd

# 6. Check app pods
kubectl get pods -n devops-bank

# 7. Get app URL
kubectl get svc frontend -n devops-bank
```

### Expected Results

```
# Nodes
NAME                                       STATUS   ROLES    AGE   VERSION
ip-10-0-3-xxx.us-west-2.compute.internal   Ready    <none>   5m    v1.30.x
ip-10-0-4-xxx.us-west-2.compute.internal   Ready    <none>   5m    v1.30.x

# App pods
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxx                 1/1     Running   0          5m
db-xxx                      1/1     Running   0          5m
frontend-xxx                1/1     Running   0          5m

# ArgoCD
NAME                                                READY   STATUS
argocd-application-controller-0                     1/1     Running
argocd-server-xxx                                   1/1     Running
```

✅ **Pass criteria:** All pods `1/1 Running`, nodes `Ready`, frontend service has `EXTERNAL-IP`

---

## Step 2 — Install Observability Stack

### Trigger

```
GitHub → Actions → Install Observability Stack → Run workflow → main
```

Expected duration: ~10 minutes

### Validate

```bash
# 1. Check all monitoring pods
kubectl get pods -n monitoring

# 2. Check Metrics Server
kubectl top nodes
kubectl top pods -n devops-bank
```

### Expected Results

```
NAME                                                     READY   STATUS
alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running
loki-0                                                   1/1     Running
loki-promtail-xxxxx (one per node)                       1/1     Running
prometheus-grafana-xxx                                   3/3     Running
prometheus-kube-prometheus-operator-xxx                  1/1     Running
prometheus-kube-prometheus-prometheus-0                  2/2     Running
prometheus-kube-state-metrics-xxx                        1/1     Running
prometheus-prometheus-node-exporter-xxx (one per node)   1/1     Running
```

✅ **Pass criteria:** All monitoring pods running, `kubectl top nodes` returns CPU/memory data

---

## Step 3 — Access ArgoCD UI

### Setup

```bash
# Port-forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password (run in separate terminal)
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### Access

Open `https://localhost:8080`

> ⚠️ You will see a certificate warning — this is expected (self-signed cert).
> Click **Advanced** → **Proceed to localhost (unsafe)**

Login credentials:
- Username: `admin`
- Password: output from command above

### Validate

Check the following in ArgoCD UI:

| Item | Expected Value |
|------|---------------|
| Application name | `devops-bank-app` |
| Sync Status | `Synced` |
| Health Status | `Healthy` |
| Sync Policy | `Automated` |
| Repository | `github.com/Manish12588/DevOps-Bank-App` |
| Path | `k8s/` |
| Namespace | `devops-bank` |

All resources (Deployments, Services, PVCs, ConfigMaps) should show green.

### CLI alternative

```bash
# Check application status via CLI
kubectl get application -n argocd

# Detailed status
kubectl describe application devops-bank-app -n argocd
```

✅ **Pass criteria:** Application shows `Synced` and `Healthy`

---

## Step 4 — Access Grafana Dashboard

### Get URL

```bash
kubectl get svc prometheus-grafana -n monitoring
# Copy the EXTERNAL-IP value
```

### Access

Open `http://<EXTERNAL-IP>`

Login credentials:
- Username: `admin`
- Password: value of `GRAFANA_PASSWORD` GitHub secret

### Validate Datasources

1. Go to **Connections → Data sources**
2. Verify both datasources exist and are connected:

| Datasource | URL | Default |
|-----------|-----|---------|
| Prometheus | `http://prometheus-kube-prometheus-prometheus:9090` | ✅ Yes |
| Loki | `http://loki:3100` | No |

### Validate Dashboards

1. Go to **Dashboards**
2. Open **Kubernetes / Compute Resources / Cluster**
   - Verify CPU utilization graph showing data
   - Verify Memory utilization showing data
   - Verify all namespaces visible (devops-bank, monitoring, argocd, kube-system)

3. Open **Kubernetes / Compute Resources / Namespace (Pods)**
   - Select namespace: `devops-bank`
   - Verify backend, db, frontend pods showing individual metrics

✅ **Pass criteria:** Both datasources connected, dashboards showing live metrics

---

## Step 5 — Test GitOps (ArgoCD Auto-Sync)

This test verifies that ArgoCD automatically deploys changes pushed to Git — without any manual `kubectl apply`.

### Test

```bash
# Scale backend to 2 replicas
sed -i 's/replicas: 1/replicas: 2/' k8s/backend/deployment.yml

# Push to Git
git add k8s/backend/deployment.yml
git commit -m "test: scale backend to 2 replicas to verify GitOps"
git push origin main
```

### Watch ArgoCD Deploy

```bash
# Watch pods in real time
kubectl get pods -n devops-bank -w
```

### Expected Result

Within ~1 minute, a second backend pod should appear automatically:

```
NAME                        READY   STATUS              RESTARTS   AGE
backend-xxx-pod1            1/1     Running             0          10m
backend-xxx-pod2            0/1     ContainerCreating   0          5s
backend-xxx-pod2            1/1     Running             0          15s
```

### Verify in ArgoCD UI

- Application should show **OutOfSync** briefly then **Synced**
- Backend deployment should show `2/2` replicas

### Revert

```bash
sed -i 's/replicas: 2/replicas: 1/' k8s/backend/deployment.yml
git add k8s/backend/deployment.yml
git commit -m "revert: scale backend back to 1 replica after GitOps test"
git push origin main
```

✅ **Pass criteria:** Second pod appears automatically within 1 minute of git push, no manual kubectl required

---

## Step 6 — Test Application + Verify Logs in Grafana

### 6a — Test Application

Open the app URL in your browser.

**Register a new user:**
1. Click **Create one**
2. Fill in: Full Name, Email, Password (min 8 chars)
3. Click **Create Account**
4. Verify redirect to dashboard

**Perform banking operations:**
1. Click **New Account** → Create a Savings account with initial balance
2. Click on the account → Click **Deposit** → Enter amount
3. Click **Withdraw** → Enter amount
4. Create a second account
5. Click **Transfer** → Transfer between accounts
6. Verify transaction history updates

### 6b — Verify Logs in Grafana (Loki)

1. Open Grafana → **Explore** (compass icon in sidebar)
2. Select **Loki** datasource from dropdown
3. Run query to see all app logs:
```
{namespace="devops-bank"}
```
4. Verify HTTP request logs appear for your actions

5. Filter backend logs only:
```
{namespace="devops-bank", app="backend"}
```
6. Verify POST requests visible:
   - `POST /api/auth/register`
   - `POST /api/auth/login`
   - `POST /api/accounts`
   - `POST /api/accounts/:id/deposit`
   - `POST /api/accounts/:id/withdraw`
   - `POST /api/transfer`

### 6c — Verify Metrics Spike in Grafana

1. Go to **Dashboards → Kubernetes / Compute Resources / Namespace (Pods)**
2. Select namespace: `devops-bank`
3. Perform several banking operations in the app
4. Observe slight CPU/memory increase in backend pod during operations

✅ **Pass criteria:** User created, transactions work, logs visible in Loki, metrics visible in Prometheus

---

## Step 7 — Test CI/CD Pipeline (DevSecOps)

### Trigger

Make a change to app code to trigger the full DevSecOps pipeline:

```bash
# Add a comment to backend to trigger pipeline
echo "// $(date)" >> app/backend/server.js

git add app/backend/server.js
git commit -m "test: trigger DevSecOps pipeline"
git push origin main
```

### Validate Pipeline Stages

```
GitHub → Actions → DevSecOps End To End Pipeline
```

Verify all stages pass in order:

| Stage | Tool | Expected |
|-------|------|---------|
| Code Quality | ESLint | ✅ Pass |
| Secrets Scan | Gitleaks | ✅ No secrets found |
| Dependency Scan | npm audit | ✅ Pass |
| Docker Lint | Hadolint | ✅ Pass |
| Build & Push | Docker | ✅ Images pushed to DockerHub |
| Image Scan | Trivy | ✅ No critical vulnerabilities |
| Deploy EKS | ArgoCD | ✅ Synced |

### Verify New Image Deployed

```bash
# Check image SHA updated in deployment
kubectl get deployment backend -n devops-bank \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

✅ **Pass criteria:** All pipeline stages green, new image deployed to EKS

---

## Step 8 — Test Destroy & Rebuild (Idempotency)

This test verifies the infrastructure can be destroyed and rebuilt cleanly.

### Destroy

```
GitHub → Actions → Destroy Infrastructure → Run workflow
→ environment: eks
```

Verify in workflow logs:
- Sealed Secrets key backed up to S3
- All LoadBalancer services deleted
- All ELBs deleted
- All k8s-* security groups deleted
- terraform destroy completes successfully

### Verify Clean

```bash
aws eks list-clusters --region us-west-2
# Expected: { "clusters": [] }

aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=devops-bank-vpc" \
  --query "Vpcs[*].VpcId" --output text --region us-west-2
# Expected: empty
```

### Rebuild

```
GitHub → Actions → Provision EKS Infrastructure → Run workflow → main
```

Verify:
- App deploys without re-sealing secrets (key restored from S3)
- All pods running
- App accessible

✅ **Pass criteria:** Clean destroy, successful rebuild, no manual intervention required

---

## Test Summary

| Test | Description | Expected Duration |
|------|-------------|-------------------|
| Step 1 | EKS Provisioning | ~25 mins |
| Step 2 | Observability Stack | ~10 mins |
| Step 3 | ArgoCD UI | ~2 mins |
| Step 4 | Grafana Dashboards | ~5 mins |
| Step 5 | GitOps Auto-Deploy | ~2 mins |
| Step 6 | App + Logs + Metrics | ~10 mins |
| Step 7 | CI/CD Pipeline | ~8 mins |
| Step 8 | Destroy & Rebuild | ~45 mins |

---

## 🔮 Future Testing (Planned)

Automated testing will be added in a future iteration:

| Test Type | Tool | Coverage |
|-----------|------|----------|
| Unit tests | Jest | Backend API endpoints |
| Integration tests | Supertest | Database operations |
| E2E tests | Playwright | Frontend user flows |
| Load tests | k6 | Performance under load |
| Security tests | OWASP ZAP | Dynamic application security testing |

These will be integrated as additional stages in the DevSecOps pipeline, running before the Docker build stage.