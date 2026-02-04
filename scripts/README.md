# Deployment Scripts

Helper scripts for managing Goalixa landing page deployments with version tracking.

## Scripts

### 1. Check Version
View the currently deployed version and status:

```bash
./scripts/check-version.sh
```

**Output:**
- Deployment version number
- Git commit SHA
- Deployment timestamp
- Container image tag
- Pod status
- Recent deployment history

### 2. Deploy Specific Version
Deploy a specific version by commit SHA, build number, or latest:

```bash
# Deploy latest build
./scripts/deploy-version.sh latest

# Deploy specific commit SHA
./scripts/deploy-version.sh abc123def

# Deploy specific build number
./scripts/deploy-version.sh 42
```

### 3. Rollback
Rollback to a previous version:

```bash
# Rollback to previous version
./scripts/rollback.sh

# Rollback to specific revision
./scripts/rollback.sh 5
```

## Image Tags

Every build creates multiple tags for flexibility:

- `latest` - Always points to the most recent build
- `<commit-sha>` - Specific git commit (e.g., `abc123def456...`)
- `<build-number>` - GitHub Actions run number (e.g., `42`)

## Version Tracking

The deployment includes annotations for tracking:

```yaml
deployment.kubernetes.io/revision-sha: "abc123..."
deployment.kubernetes.io/revision-number: "42"
deployment.kubernetes.io/deployed-at: "2025-01-15T10:30:00Z"
deployment.kubernetes.io/deployed-by: "username"
```

## Quick Commands

```bash
# Check what's running
./scripts/check-version.sh

# Deploy latest version
./scripts/deploy-version.sh latest

# Deploy specific commit
git log --oneline -5  # see recent commits
./scripts/deploy-version.sh <commit-sha>

# Rollback if something breaks
./scripts/rollback.sh

# View deployment history
kubectl rollout history deployment/landing -n goalixa-landing

# Manual image update
kubectl set image deployment/landing \
  landing=ghcr.io/goalixa/landing:abc123 \
  -n goalixa-landing
```

## Debugging

```bash
# Check which image tag is running
kubectl get pods -n goalixa-landing -l app=landing -o jsonpath='{.items[0].spec.containers[0].image}'

# Exec into pod to verify content
POD=$(kubectl get pods -n goalixa-landing -l app=landing -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n goalixa-landing $POD -- cat /usr/share/nginx/html/index.html | grep -o 'auth.goalixa.com' | wc -l

# View pod logs
kubectl logs -n goalixa-landing -l app=landing --tail=50 -f
```

## CI/CD Integration

### 4. Setup Self-Hosted Runner
Install and configure a GitHub Actions self-hosted runner on your VM:

```bash
# Setup runner (requires organization name and token)
sudo ./scripts/setup-runner.sh <ORG_NAME> <RUNNER_TOKEN> [RUNNER_NAME]

# Example
sudo ./scripts/setup-runner.sh goalixa TOKEN123 my-runner-01
```

**What it installs:**
- Docker (for building images)
- kubectl (for deploying to Kubernetes)
- GitHub Actions Runner (systemd service)
- Dedicated `actions` user with proper permissions

### 5. Manage Runner
Manage the self-hosted runner service:

```bash
# Check runner status
./scripts/runner-manager.sh status

# Start/stop/restart runner
./scripts/runner-manager.sh start
./scripts/runner-manager.sh stop
./scripts/runner-manager.sh restart

# View live logs
./scripts/runner-manager.sh logs

# Update runner to latest version
./scripts/runner-manager.sh update

# Run diagnostics
./scripts/runner-manager.sh diagnostics

# Remove runner
./scripts/runner-manager.sh uninstall
```

## CI/CD Integration

The GitHub Actions workflow uses self-hosted runners and automatically:

1. Builds image on push to `main`
2. Tags with: `latest`, `<commit-sha>`, `<build-number>`
3. Pushes to GitHub Container Registry
4. Deploys to Kubernetes with version annotations
5. Waits for successful rollout

### Required GitHub Secrets

Add these as **Organization secrets** (Settings → Secrets → Actions):

| Secret | Description | How to get |
|--------|-------------|------------|
| `KUBECONFIG` | Base64-encoded kubeconfig | `cat ~/.kube/config \| base64` |

### Workflow Labels

The runner uses labels: `ubuntu`, `self-hosted`, `docker`, `kubectl`
