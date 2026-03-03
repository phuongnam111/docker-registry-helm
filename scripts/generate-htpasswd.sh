#!/bin/bash
# ====================================================================
# Generate htpasswd credentials for Docker Registry authentication
# Usage: ./generate-htpasswd.sh [username] [password]
# ====================================================================

set -euo pipefail

USERNAME=${1:-admin}
PASSWORD=${2:-registryP@ss123}
OUTPUT_FILE="auth/htpasswd"

echo "========================================"
echo "  Generating htpasswd credentials"
echo "  Username: $USERNAME"
echo "========================================"

# Create auth directory
mkdir -p auth

# Generate htpasswd using registry:2 image
docker run --rm --entrypoint htpasswd   registry:2 -Bbn "$USERNAME" "$PASSWORD" > "$OUTPUT_FILE"

echo "  ✓ htpasswd file created: $OUTPUT_FILE"

# Generate base64 for values.yaml
B64=$(cat "$OUTPUT_FILE" | base64 -w 0 2>/dev/null || cat "$OUTPUT_FILE" | base64)
echo ""
echo "  Base64 value for values.yaml:"
echo "  auth:"
echo "    htpasswd: \"$B64\""
echo ""
echo "  Or install with:"
echo "  helm install registry ./charts/docker-registry --set auth.htpasswd=$B64"
echo "========================================"