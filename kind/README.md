# kind

Local Kubernetes cluster configuration using KIND (Kubernetes in Docker).

## Structure

```
kind/
└── kind-config.yml    # KIND cluster config with port mappings
```

## Prerequisites

```bash
# Install KIND
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## Create the local cluster

```bash
kind create cluster --config kind/kind-config.yml --name devops-bank
kubectl get nodes
```

## Deploy the app locally

```bash
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/configmap.yml

# Create secret manually (no Sealed Secrets needed locally)
kubectl create secret generic devops-bank-secret \
  --from-literal=DB_PASSWORD=bankpass \
  --from-literal=DB_USER=bankuser \
  --from-literal=JWT_SECRET=$(openssl rand -hex 32) \
  -n devops-bank

kubectl apply -f k8s/database/
kubectl apply -f k8s/backend/
kubectl apply -f k8s/frontend/

# Access: http://localhost:8080
```

## Delete the cluster

```bash
kind delete cluster --name devops-bank
```

## KIND vs EKS

| Feature | KIND (local) | EKS (cloud) |
|---------|-------------|-------------|
| Cost | Free | ~$0.10/hr |
| Storage | hostPath | EBS gp2 |
| LoadBalancer | NodePort | AWS ELB |
| Secrets | Plain secrets | Sealed Secrets |
| Use case | Development/testing | Production |
