#!/bin/bash
# ====================================================================
# Generate self-signed TLS certificate for custom domain
# Usage: ./generate-tls.sh [domain]
# ====================================================================

set -euo pipefail

DOMAIN=${1:-registry.local}
CERT_DIR="certs"
DAYS=365

echo "========================================"
echo "  Generating TLS certificate"
echo "  Domain: $DOMAIN"
echo "  Valid for: $DAYS days"
echo "========================================"

mkdir -p "$CERT_DIR"

# Generate self-signed certificate
openssl req -x509 -nodes   -days "$DAYS"   -newkey rsa:4096   -keyout "$CERT_DIR/tls.key"   -out "$CERT_DIR/tls.crt"   -subj "/CN=$DOMAIN"   -addext "subjectAltName=DNS:$DOMAIN"

echo "  ✓ Certificate created:"
echo "    $CERT_DIR/tls.crt"
echo "    $CERT_DIR/tls.key"

# Generate base64 for values.yaml
CRT_B64=$(cat "$CERT_DIR/tls.crt" | base64 -w 0 2>/dev/null || cat "$CERT_DIR/tls.crt" | base64)
KEY_B64=$(cat "$CERT_DIR/tls.key" | base64 -w 0 2>/dev/null || cat "$CERT_DIR/tls.key" | base64)

echo ""
echo "  Base64 values for values.yaml:"
echo "  tls:"
echo "    crt: \"$CRT_B64\""
echo "    key: \"$KEY_B64\""
echo ""
echo "  Or install with:"
echo "  helm install registry ./charts/docker-registry \\"
echo "    --set tls.crt=$CRT_B64 \\"
echo "    --set tls.key=$KEY_B64"
echo "========================================"