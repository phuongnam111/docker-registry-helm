# Docker Registry Helm Chart

Deploy a private Docker Registry on Kubernetes with authentication,
TLS, garbage collection, and Redis metadata caching.

## Features

| Feature | Description |
|---------|-------------|
| Image | registry:2 (Docker Distribution) |
| Authentication | htpasswd-based with custom user accounts |
| TLS/Domain | Custom domain via Ingress with TLS termination |
| Garbage Collection | CronJob with configurable schedule |
| Redis Cache | Metadata caching for improved performance |
| CI/CD | GitHub Actions for helm lint + yamllint |

## Prerequisites

- Docker
- Kind or Minikube
- kubectl
- Helm 3.x
- openssl (for TLS generation)

## Quick Start

```bash
# 1. Clone & setup cluster
git clone <repo-url>
cd docker-registry-helm
chmod +x scripts/*.sh
./scripts/setup-cluster.sh

# 2. Generate credentials & TLS
./scripts/generate-htpasswd.sh admin mySecureP@ss
./scripts/generate-tls.sh registry.local

# 3. Install chart
helm install registry ./charts/docker-registry \
  --set auth.htpasswd=$(cat auth/htpasswd | base64 -w 0) \
  --set tls.crt=$(cat certs/tls.crt | base64 -w 0) \
  --set tls.key=$(cat certs/tls.key | base64 -w 0)

# 4. Verify
helm test registry
kubectl get pods -n registry
```

## Usage — Push/Pull Images

```bash
# Login
docker login registry.local -u admin -p mySecureP@ss

# Tag & push
docker tag myapp:latest registry.local/myapp:v1.0
docker push registry.local/myapp:v1.0

# Pull
docker pull registry.local/myapp:v1.0
```

## Configuration

All values are customizable via values.yaml or --set flags:

| Parameter | Description | Default |
|-----------|-------------|---------|
| namespace | Kubernetes namespace | registry |
| image.tag | Registry image tag | 2 |
| replicaCount | Number of replicas | 1 |
| auth.enabled | Enable htpasswd auth | true |
| tls.enabled | Enable TLS | true |
| ingress.host | Custom domain | registry.local |
| persistence.size | Storage size | 20Gi |
| redis.enabled | Enable Redis cache | true |
| gc.enabled | Enable garbage collection | true |
| gc.schedule | GC cron schedule | 0 2 * * * |
| gc.deleteUntagged | Delete untagged manifests | true |

### Custom Values Example

```bash
helm install registry ./charts/docker-registry \
  -f my-values.yaml \
  --set ingress.host=myregistry.company.com \
  --set gc.schedule="0 3 * * 0" \
  --set persistence.size=50Gi
```

## Architecture

```
┌─────────────────────────────────────────────┐
│                  Ingress                     │
│          (registry.local + TLS)              │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│            Registry Service                  │
│              (ClusterIP:5000)                │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│          Registry Deployment                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│  │ ConfigMap│ │ htpasswd │ │     PVC      │ │
│  │ (config) │ │ (Secret) │ │  (Storage)   │ │
│  └──────────┘ └──────────┘ └──────────────┘ │
└──────────────────┬──────────────────────────┘
                   │
       ┌───────────┴───────────┐
       │                       │
┌──────▼──────┐    ┌───────────▼──────────────┐
│    Redis    │    │   GC CronJob             │
│  (Cache)    │    │  (Scheduled cleanup)     │
└─────────────┘    └──────────────────────────┘
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Ingress not working | Verify ingress controller: kubectl get pods -n ingress-nginx |
| Auth failed | Regenerate htpasswd: ./scripts/generate-htpasswd.sh |
| TLS errors | Check cert: openssl x509 -in certs/tls.crt -text -noout |
| GC not running | Check cronjob: kubectl get cronjobs -n registry |
| Redis not connected | Verify: kubectl logs -n registry <registry-pod> |

## Author
nam.vp — SRE Engineer