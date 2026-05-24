# helm/values

Helm chart values for the observability stack.

## Structure

```
helm/
└── values/
    ├── prometheus-values.yml   # kube-prometheus-stack config
    └── loki-values.yml         # loki-stack config
```

## prometheus-values.yml

Configures the `kube-prometheus-stack` Helm chart which installs:
- **Prometheus** — metrics collection and storage (10Gi EBS volume)
- **Grafana** — dashboards (LoadBalancer service, admin/admin123)
- **AlertManager** — alerting (2Gi EBS volume)
- **Node Exporter** — node-level metrics
- **Kube State Metrics** — Kubernetes object metrics

Datasources are configured automatically via the `observability.yml` GitHub Actions workflow using the Grafana API.

## loki-values.yml

Configures the `loki-stack` Helm chart which installs:
- **Loki** — log aggregation backend (10Gi EBS volume)
- **Promtail** — log collection agent (runs as DaemonSet on all nodes)

## Install

```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus + Grafana
helm upgrade --install prometheus \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values helm/values/prometheus-values.yml

# Install Loki + Promtail
helm upgrade --install loki \
  grafana/loki-stack \
  --namespace monitoring \
  --values helm/values/loki-values.yml
```

Or use the GitHub Actions workflow:
```
GitHub → Actions → Install Observability Stack → Run workflow
```
