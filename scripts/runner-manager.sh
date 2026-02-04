#!/bin/bash
#
# GitHub Actions Runner Management Script
#
# Usage:
#   ./scripts/runner-manager.sh [status|start|stop|restart|logs|uninstall|update]
#

RUNNER_DIR="/opt/github-runner"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

case "$1" in
    status)
        log_info "Runner status:"
        if [ -f "$RUNNER_DIR/svc.sh" ]; then
            sudo "$RUNNER_DIR/svc.sh" status
        else
            log_error "Runner not found at $RUNNER_DIR"
            exit 1
        fi
        ;;

    start)
        log_info "Starting runner..."
        if [ -f "$RUNNER_DIR/svc.sh" ]; then
            sudo "$RUNNER_DIR/svc.sh" start
            log_info "Runner started"
        else
            log_error "Runner not found at $RUNNER_DIR"
            exit 1
        fi
        ;;

    stop)
        log_info "Stopping runner..."
        if [ -f "$RUNNER_DIR/svc.sh" ]; then
            sudo "$RUNNER_DIR/svc.sh" stop
            log_info "Runner stopped"
        else
            log_error "Runner not found at $RUNNER_DIR"
            exit 1
        fi
        ;;

    restart)
        log_info "Restarting runner..."
        if [ -f "$RUNNER_DIR/svc.sh" ]; then
            sudo "$RUNNER_DIR/svc.sh" stop
            sleep 2
            sudo "$RUNNER_DIR/svc.sh" start
            log_info "Runner restarted"
        else
            log_error "Runner not found at $RUNNER_DIR"
            exit 1
        fi
        ;;

    logs)
        log_info "Runner logs (press Ctrl+C to exit):"
        sudo journalctl -u actions.runner.* -f
        ;;

    uninstall)
        log_warn "This will remove the runner service."
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f "$RUNNER_DIR/svc.sh" ]; then
                sudo "$RUNNER_DIR/svc.sh" uninstall
                log_info "Runner uninstalled"
            else
                log_error "Runner not found at $RUNNER_DIR"
                exit 1
            fi
        else
            log_info "Uninstall cancelled"
        fi
        ;;

    update)
        log_info "Updating runner to latest version..."
        cd "$RUNNER_DIR"
        if [ -f "./config.sh" ]; then
            log_info "Stopping runner..."
            sudo "$RUNNER_DIR/svc.sh" stop

            log_info "Downloading latest version..."
            sudo -u actions ./bin/updatedependencies.sh

            log_info "Starting runner..."
            sudo "$RUNNER_DIR/svc.sh" start
            log_info "Runner updated"
        else
            log_error "Runner not found at $RUNNER_DIR"
            exit 1
        fi
        ;;

    diagnostics)
        log_info "Runner diagnostics:"
        echo ""
        echo "=== System Info ==="
        uname -a
        echo ""
        echo "=== Docker Version ==="
        docker --version
        echo ""
        echo "=== Docker Status ==="
        systemctl is-active docker
        echo ""
        echo "=== kubectl Version ==="
        kubectl version --client 2>/dev/null || echo "kubectl not installed"
        echo ""
        echo "=== Disk Space ==="
        df -h /opt/github-runner
        echo ""
        echo "=== Memory ==="
        free -h
        echo ""
        echo "=== Runner Service Status ==="
        systemctl status actions.runner.* --no-pager
        ;;

    *)
        echo "GitHub Actions Runner Manager"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  status       - Show runner status"
        echo "  start        - Start runner service"
        echo "  stop         - Stop runner service"
        echo "  restart      - Restart runner service"
        echo "  logs         - Show runner logs (live)"
        echo "  uninstall    - Remove runner service"
        echo "  update       - Update runner to latest version"
        echo "  diagnostics  - Show system diagnostics"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 logs"
        ;;
esac
