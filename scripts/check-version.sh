#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE="goalixa-landing"
DEPLOYMENT="landing"

echo -e "${BLUE}=== Goalixa Landing Version Info ===${NC}\n"

# Get deployment annotations
echo -e "${GREEN}📦 Deployed Version:${NC}"
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision-number}' 2>/dev/null && echo "" || echo "N/A"

echo -e "\n${GREEN}🔖 Git Commit SHA:${NC}"
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision-sha}' 2>/dev/null | cut -c1-8 && echo "" || echo "N/A"

echo -e "\n${GREEN}🕐 Deployed At:${NC}"
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/deployed-at}' 2>/dev/null && echo "" || echo "N/A"

# Get current image
echo -e "\n${GREEN}🐳 Container Image:${NC}"
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' && echo ""

# Get pod status
echo -e "\n${GREEN}📊 Pod Status:${NC}"
kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o wide

# Get rollout status
echo -e "\n${GREEN}🔄 Rollout Status:${NC}"
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE

# Get last 5 rollout revisions
echo -e "\n${GREEN}📜 Recent Deployments:${NC}"
kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE | tail -6
