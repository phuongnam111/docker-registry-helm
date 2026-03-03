#!/bin/bash
# ====================================================================
# Setup local Kubernetes cluster using Kind
# Includes: Ingress controller for custom domain support
# ====================================================================

set -euo pipefail

CLUSTER_NAME="registry-cluster"
echo "========================================"
echo "  Setting up Kind cluster: $CLUSTER_NAME"
echo "========================================"

# 1. Check prerequisites
for cmd in kind kubectl helm docker; do
  if ! command -v $cmd &>/dev/null; then
    echo "ERROR: $cmd is not installed. Please install it first."
    exit 1
  fi
done

# 2. Create Kind cluster with ingress-ready config
echo "[1/4] Creating Kind cluster..."
cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
EOF

# 3. Install NGINX Ingress Controller
echo "[2/4] Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "[3/4] Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx   --for=condition=ready pod   --selector=app.kubernetes.io/component=controller   --timeout=120s

# 4. Add registry.local to /etc/hosts
echo "[4/4] Configuring local DNS..."
if ! grep -q "registry.local" /etc/hosts; then
  echo "127.0.0.1 registry.local" | sudo tee -a /etc/hosts
  echo "  Added registry.local to /etc/hosts"
else
  echo "  registry.local already in /etc/hosts"
fi

echo ""
echo "========================================"
echo "  ✓ Cluster '$CLUSTER_NAME' is ready!"
echo "  Next steps:"
echo "    ./scripts/generate-htpasswd.sh"
echo "    ./scripts/generate-tls.sh"
echo "    helm install registry ./charts/docker-registry"
echo "========================================"