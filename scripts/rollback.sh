#!/bin/bash

# Rollback to previous version
# Usage: ./scripts/rollback.sh [revision-number]

set -e

NAMESPACE="goalixa-landing"
DEPLOYMENT="landing"

if [ -n "$1" ]; then
  echo "🔄 Rolling back to revision $1..."
  kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE --to-revision=$1
else
  echo "🔄 Rolling back to previous version..."
  kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE
fi

echo ""
echo "⏳ Waiting for rollback to complete..."
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5m

echo ""
echo "✅ Rollback complete!"
echo ""

# Show the current version
./scripts/check-version.sh
