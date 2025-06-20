#!/bin/bash

# Higress AI Gateway - Minikube Test Environment Startup
# Optimized for minikube local development

set -e

# Configuration
HIGRESS_BIN="./bin/higress"
LOG_FILE="./higress-minikube.log"
PID_FILE="./higress-minikube.pid"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Higress is running
check_higress_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # Running
        else
            rm -f "$PID_FILE"
            return 1  # Not running
        fi
    fi
    return 1  # Not running
}

# Function to check and start minikube
ensure_minikube_running() {
    print_status "Checking minikube status..."
    if ! minikube status | grep -q "host: Running"; then
        print_status "Starting minikube..."
        minikube start --driver=docker --memory=4096 --cpus=2
        if [ $? -ne 0 ]; then
            print_error "Failed to start minikube"
            exit 1
        fi
        print_success "Minikube started successfully"
        
        # Wait for cluster to be ready
        print_status "Waiting for cluster to be ready..."
        kubectl wait --for=condition=Ready nodes --all --timeout=300s
        print_success "Cluster is ready"
    else
        print_success "Minikube is already running"
    fi
    
    # Get minikube IP
    MINIKUBE_IP=$(minikube ip)
    print_status "Minikube IP: $MINIKUBE_IP"
}

# Function to stop Higress
stop_higress() {
    if check_higress_running; then
        local pid=$(cat "$PID_FILE")
        print_status "Stopping Higress (PID: $pid)..."
        kill -TERM "$pid" 2>/dev/null || true
        
        # Wait for graceful shutdown
        for i in {1..10}; do
            if ! ps -p "$pid" > /dev/null 2>&1; then
                print_success "Higress stopped gracefully"
                rm -f "$PID_FILE"
                return 0
            fi
            sleep 1
        done
        
        # Force kill if still running
        kill -KILL "$pid" 2>/dev/null || true
        rm -f "$PID_FILE"
        print_warning "Higress force-stopped"
    else
        print_status "Higress is not running"
    fi
}

# Function to start Higress
start_higress() {
    print_status "Starting Higress for minikube testing..."
    
    # Ensure binary exists and is executable
    if [ ! -f "$HIGRESS_BIN" ]; then
        print_error "Higress binary not found at $HIGRESS_BIN"
        print_status "Building Higress binary..."
        make build || exit 1
    fi
    chmod +x "$HIGRESS_BIN"
    
    # Higress server arguments optimized for minikube
    local args=""
    args="$args --httpAddress=:8888"
    args="$args --grpcAddress=:15051"
    args="$args --ingressClass=higress"  # Use standard class for minikube
    args="$args --debug=true"
    args="$args --enableStatus=true"
    args="$args --kubeconfig=$HOME/.minikube/profiles/minikube/client.crt"
    args="$args --gatewaySelectorKey=higress" 
    args="$args --gatewaySelectorValue=higress-system-higress-gateway"
    
    # Start Higress in background
    print_status "Executing: $HIGRESS_BIN serve $args"
    nohup "$HIGRESS_BIN" serve $args > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    
    # Wait for startup
    print_status "Waiting for Higress to start..."
    local started=false
    for i in {1..30}; do
        if check_higress_running; then
            # Check if HTTP server is responding
            if curl -s http://localhost:8888/ready > /dev/null 2>&1; then
                started=true
                break
            fi
        fi
        sleep 2
        echo -n "."
    done
    echo
    
    if [ "$started" = true ]; then
        print_success "Higress started successfully!"
        print_status "PID: $(cat $PID_FILE)"
        print_status "HTTP Server: http://localhost:8888"
        print_status "gRPC Server: localhost:15051"
        print_status "Minikube IP: $MINIKUBE_IP"
        print_status "Log file: $LOG_FILE"
        return 0
    else
        print_error "Failed to start Higress"
        if [ -f "$LOG_FILE" ]; then
            print_status "Last 20 lines of log:"
            tail -20 "$LOG_FILE"
        fi
        return 1
    fi
}

# Function to show status
show_status() {
    # Check minikube status
    print_status "=== Minikube Status ==="
    minikube status
    
    if minikube status | grep -q "host: Running"; then
        MINIKUBE_IP=$(minikube ip)
        print_success "Minikube is running at $MINIKUBE_IP"
    else
        print_warning "Minikube is not running"
        return 1
    fi
    
    # Check Higress status
    print_status "=== Higress Status ==="
    if check_higress_running; then
        local pid=$(cat "$PID_FILE")
        print_success "Higress is running (PID: $pid)"
        
        # Test endpoints
        if curl -s http://localhost:8888/ready > /dev/null 2>&1; then
            print_success "HTTP server responding on port 8888"
        else
            print_warning "HTTP server not responding"
        fi
    else
        print_warning "Higress is not running"
    fi
}

# Function to setup port forwarding for services
setup_port_forwarding() {
    print_status "Setting up port forwarding for minikube services..."
    
    # Kill existing port forwards
    pkill -f "kubectl.*port-forward" 2>/dev/null || true
    sleep 2
    
    # Setup port forwards in background (if services exist)
    if kubectl get svc -n higress-system 2>/dev/null | grep -q higress-gateway; then
        print_status "Setting up Higress Gateway port forward..."
        kubectl port-forward -n higress-system svc/higress-gateway 8080:80 8443:443 > /dev/null 2>&1 &
        print_success "Higress Gateway accessible at http://localhost:8080"
    fi
}

# Function to show minikube-specific test commands
show_test_commands() {
    if ! minikube status | grep -q "host: Running"; then
        print_error "Minikube is not running"
        return 1
    fi
    
    MINIKUBE_IP=$(minikube ip)
    
    print_status "=== Minikube Test Commands ==="
    echo ""
    print_status "Basic Higress Health Checks:"
    echo "  curl http://localhost:8888/ready"
    echo "  curl http://localhost:8888/debug/configz"
    echo ""
    print_status "Minikube Cluster Access:"
    echo "  kubectl get pods -A"
    echo "  kubectl get svc -A" 
    echo "  minikube dashboard"
    echo ""
    print_status "Deploy Test Application:"
    echo "  kubectl apply -f samples/quickstart.yaml"
    echo ""
    if kubectl get svc -n higress-system 2>/dev/null | grep -q higress-gateway; then
        print_status "Access via Minikube IP:"
        echo "  curl http://$MINIKUBE_IP:$(kubectl get svc -n higress-system higress-gateway -o jsonpath='{.spec.ports[0].nodePort}')"
    fi
}

# Main script logic
case "${1:-start}" in
    start)
        ensure_minikube_running
        if check_higress_running; then
            print_warning "Higress is already running"
            show_status
        else
            start_higress
            setup_port_forwarding
        fi
        ;;
    stop)
        stop_higress
        print_status "Stopping port forwards..."
        pkill -f "kubectl.*port-forward" 2>/dev/null || true
        ;;
    restart)
        stop_higress
        pkill -f "kubectl.*port-forward" 2>/dev/null || true
        sleep 2
        ensure_minikube_running
        start_higress
        setup_port_forwarding
        ;;
    status)
        show_status
        ;;
    test)
        show_test_commands
        ;;
    logs)
        if [ -f "$LOG_FILE" ]; then
            print_status "Showing Higress logs (press Ctrl+C to exit):"
            tail -f "$LOG_FILE"
        else
            print_error "Log file not found: $LOG_FILE"
        fi
        ;;
    minikube-start)
        ensure_minikube_running
        ;;
    minikube-stop)
        print_status "Stopping minikube..."
        minikube stop
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|test|logs|minikube-start|minikube-stop}"
        echo ""
        echo "Minikube-optimized commands:"
        echo "  start         - Start minikube and Higress"
        echo "  stop          - Stop Higress and port forwards"
        echo "  restart       - Restart everything"
        echo "  status        - Show minikube and Higress status"
        echo "  test          - Show test commands for minikube"
        echo "  logs          - Show and follow Higress logs"
        echo "  minikube-start- Start only minikube"
        echo "  minikube-stop - Stop minikube"
        exit 1
        ;;
esac 