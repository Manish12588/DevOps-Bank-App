# .github/workflows

GitHub Actions CI/CD pipelines for the DevOps Bank App.

## Workflows

| File | Trigger | Purpose |
|------|---------|---------|
| `devsecops-pipeline.yml` | Push to `main` (app changes) | Main orchestrator — runs all scans then deploys |
| `code-quality-check.yml` | Called by pipeline | ESLint code quality check |
| `secrets-scan.yml` | Called by pipeline | Gitleaks secret scanning |
| `dependency-scan.yml` | Called by pipeline | npm audit dependency vulnerabilities |
| `docker-lint.yml` | Called by pipeline | Hadolint Dockerfile linting |
| `docker-build-and-push.yml` | Called by pipeline | Build + push images, update k8s SHA tags |
| `docker-image-scan.yml` | Called by pipeline | Trivy container vulnerability scan |
| `deploy-ec2.yml` | Manual | SSH deploy to EC2 staging |
| `deploy-eks.yml` | Called by pipeline | Verify ArgoCD sync on EKS |
| `infra-ec2.yml` | Manual | Provision EC2 with Terraform + Ansible |
| `infra-eks.yml` | Manual | Provision EKS cluster with all components |
| `infra-destroy.yml` | Manual | Destroy EC2 or EKS infrastructure |
| `observability.yml` | Manual | Install Prometheus + Grafana + Loki |

## Pipeline Flow

```
Push to main (app/** changes)
        │
        ▼
devsecops-pipeline.yml
        │
        ├── code-quality-check.yml   (ESLint)
        ├── secrets-scan.yml         (Gitleaks)
        ├── dependency-scan.yml      (npm audit)
        ├── docker-lint.yml          (Hadolint)
        │
        ▼ (all scans pass)
        │
        ├── docker-build-and-push.yml
        │   ├── Build backend image
        │   ├── Build frontend image
        │   ├── Push to Docker Hub with SHA tag
        │   └── Update k8s/*/deployment.yml with new SHA
        │
        ├── docker-image-scan.yml    (Trivy)
        │
        └── deploy-eks.yml
            └── ArgoCD detects Git change → auto-deploys
```

## Required GitHub Secrets

| Secret | Used By |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | All AWS workflows |
| `AWS_SECRET_ACCESS_KEY` | All AWS workflows |
| `DOCKERHUB_USERNAME` | docker-build-and-push |
| `DOCKERHUB_TOKEN` | docker-build-and-push |
| `JWT_SECRET` | infra-ec2, deploy-ec2 |
| `DB_PASSWORD` | infra-ec2, deploy-ec2 |
| `EC2_SSH_PRIVATE_KEY` | deploy-ec2 |
| `EC2_SSH_HOST` | deploy-ec2 (auto-updated by infra-ec2) |
| `EC2_SSH_USER` | deploy-ec2 |
| `GH_PAT` | docker-build-and-push (updates EC2_SSH_HOST) |
