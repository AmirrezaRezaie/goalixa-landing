#!/bin/bash

# Deploy a specific version of the landing page
# Usage: ./scripts/deploy-version.sh <commit-sha|run-number|latest>

set -e

NAMESPACE="goalixa-landing"
DEPLOYMENT="landing"
IMAGE_BASE="ghcr.io/goalixa/landing"

if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  echo ""
  echo "Examples:"
  echo "  $0 latest              # Deploy latest build"
  echo "  $0 abc123              # Deploy specific commit SHA"
  echo "  $0 42                  # Deploy build number 42"
  exit 1
fi

VERSION=$1

echo "🚀 Deploying version: $VERSION"
echo ""

# Update the image
kubectl set image deployment/$DEPLOYMENT \
  landing=$IMAGE_BASE:$VERSION \
  -n $NAMESPACE

# Annotate with deployment info
kubectl annotate deployment/$DEPLOYMENT \
  -n $NAMESPACE \
  deployment.kubernetes.io/deployed-version="$VERSION" \
  deployment.kubernetes.io/deployed-at="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  deployment.kubernetes.io/deployed-by="$(whoami)" \
  --overwrite

echo ""
echo "⏳ Waiting for rollout to complete..."
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5m

echo ""
echo "✅ Deployment complete!"
echo ""

# Show the new version info
./scripts/check-version.sh
