# Goalixa Landing - Deployment Guide

## Quick Start

### Check Current Version
```bash
./scripts/check-version.sh
```

### Deploy Latest Version
```bash
./scripts/deploy-version.sh latest
```

### Rollback to Previous Version
```bash
./scripts/rollback.sh
```

## Version Tracking System

Every deployment is tagged with:
- **Build Number**: Auto-incrementing (1, 2, 3...)
- **Commit SHA**: Full git commit hash
- **Timestamp**: When it was deployed

## Image Tags

Each build creates 3 tags:
```
ghcr.io/goalixa/landing:latest
ghcr.io/goalixa/landing:<commit-sha>
ghcr.io/goalixa/landing:<build-number>
```

## Manual Deployment

```bash
# 1. Build and push
docker build -t ghcr.io/goalixa/landing:v1.0.0 .
docker push ghcr.io/goalixa/landing:v1.0.0

# 2. Deploy to Kubernetes
kubectl set image deployment/landing \
  landing=ghcr.io/goalixa/landing:v1.0.0 \
  -n goalixa-landing

# 3. Check rollout status
kubectl rollout status deployment/landing -n goalixa-landing
```

## Automated CI/CD

On every push to `main`:
1. ✅ Image is built automatically
2. ✅ Tagged with commit SHA and build number
3. ✅ Pushed to GitHub Container Registry
4. ✅ Deployed to Kubernetes (if KUBECONFIG secret is set)
5. ✅ Version annotations are added

## Setup GitHub Auto-Deploy

To enable automatic deployment from GitHub Actions:

```bash
# 1. Get your kubeconfig
cat ~/.kube/config | base64

# 2. Add as GitHub Organization Secret named: KUBECONFIG
# Go to: https://github.com/organizations/YOUR_ORG/settings/secrets/actions
# Name: KUBECONFIG
# Value: <paste base64 output>
```

## Self-Hosted Runner Setup

This project uses self-hosted GitHub Actions runners for CI/CD. Runners execute on your own infrastructure.

### Quick Setup

1. **Get a runner token from GitHub**:
   - Go to: https://github.com/organizations/YOUR_ORG/settings/actions/runners
   - Click "New runner"
   - Copy the token

2. **Run the setup script on your VM**:
```bash
chmod +x scripts/setup-runner.sh
sudo ./scripts/setup-runner.sh <ORGANIZATION_NAME> <RUNNER_TOKEN> [RUNNER_NAME]
```

Example:
```bash
sudo ./scripts/setup-runner.sh goalixa TOKEN123 my-runner-01
```

3. **Verify runner is running**:
```bash
./scripts/runner-manager.sh status
```

### What Gets Installed

- Docker (for building images)
- kubectl (for deploying to Kubernetes)
- GitHub Actions Runner (as a systemd service)
- Dedicated `actions` user with docker group access

### Managing Runners

```bash
# Check status
./scripts/runner-manager.sh status

# View logs
./scripts/runner-manager.sh logs

# Restart runner
./scripts/runner-manager.sh restart

# Update runner
./scripts/runner-manager.sh update

# Run diagnostics
./scripts/runner-manager.sh diagnostics

# Uninstall runner
./scripts/runner-manager.sh uninstall
```

### Manual Setup (Without Script)

If you prefer manual setup or need customization:

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y docker.io kubectl curl jq git

# Add your user to docker group
sudo usermod -aG docker $USER

# Download and configure runner
mkdir -p /opt/github-runner
cd /opt/github-runner

# Download latest runner (adjust arch if needed)
curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/latest/download/actions-runner-linux-x64-<version>.tar.gz
tar xzf ./actions-runner.tar.gz

# Configure (use token from GitHub)
./config.sh --url https://github.com/YOUR_ORG --token YOUR_TOKEN

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

### Troubleshooting Runner Issues

**Runner not showing in GitHub:**
```bash
./scripts/runner-manager.sh logs
# Check for authentication or network errors
```

**Docker permission denied:**
```bash
# Ensure runner user is in docker group
sudo usermod -aG docker actions
./scripts/runner-manager.sh restart
```

**kubectl not working:**
```bash
# Check if kubeconfig is configured
echo $KUBECONFIG  # Should be set or have ~/.kube/config

# Test connection
kubectl get nodes
```

## Troubleshooting

### Changes not appearing?
```bash
# Check which version is running
./scripts/check-version.sh

# Check if new image was built
# Visit: https://github.com/YOUR_USERNAME/goalixa-landing/packages

# Force pull new image
kubectl rollout restart deployment/landing -n goalixa-landing
```

### Which version is in production?
```bash
kubectl get deployment landing -n goalixa-landing -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### View deployment history
```bash
kubectl rollout history deployment/landing -n goalixa-landing
```

### Rollback to specific version
```bash
# List history first
kubectl rollout history deployment/landing -n goalixa-landing

# Rollback to revision number
./scripts/rollback.sh 3
```

## Version Comparison

```bash
# See what's in the running container
POD=$(kubectl get pods -n goalixa-landing -l app=landing -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n goalixa-landing $POD -- cat /usr/share/nginx/html/index.html | head -50

# Compare with local file
diff <(kubectl exec -n goalixa-landing $POD -- cat /usr/share/nginx/html/index.html) index.html
```

## See Also

- [scripts/README.md](./scripts/README.md) - Detailed script documentation
- [.github/workflows/main.yml](./.github/workflows/main.yml) - CI/CD workflow
- [k8s/base/](./k8s/base/) - Kubernetes manifests
