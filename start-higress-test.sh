#!/bin/bash

# Higress AI Gateway - Test Environment Startup Script
# This script starts the Higress component for testing purposes

set -e

# Configuration
HIGRESS_BIN="./bin/higress"
LOG_FILE="./higress-test.log"
PID_FILE="./higress-test.pid"
KUBECONFIG="${HOME}/.kube/config"

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

# Function to check if Higress is already running
check_running() {
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

# Function to stop existing Higress instance
stop_higress() {
    if check_running; then
        local pid=$(cat "$PID_FILE")
        print_status "Stopping existing Higress instance (PID: $pid)..."
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
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if binary exists
    if [ ! -f "$HIGRESS_BIN" ]; then
        print_error "Higress binary not found at $HIGRESS_BIN"
        print_status "Building Higress binary..."
        make build
        if [ ! -f "$HIGRESS_BIN" ]; then
            print_error "Failed to build Higress binary"
            exit 1
        fi
    fi
    
    # Check if binary is executable
    if [ ! -x "$HIGRESS_BIN" ]; then
        chmod +x "$HIGRESS_BIN"
    fi
    
    # Check kubeconfig
    if [ ! -f "$KUBECONFIG" ]; then
        print_warning "Kubeconfig not found at $KUBECONFIG"
        print_status "Will try to use in-cluster configuration"
    else
        print_success "Kubeconfig found at $KUBECONFIG"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to start Higress
start_higress() {
    print_status "Starting Higress component for testing..."
    
    # Higress server arguments for testing
    local args=""
    args="$args --httpAddress=:8888"
    args="$args --grpcAddress=:15051"
    args="$args --ingressClass=higress-local"
    args="$args --debug=true"
    args="$args --enableStatus=true"
    args="$args --gatewaySelectorKey=higress"
    args="$args --gatewaySelectorValue=higress-system-higress-gateway"
    
    # Add kubeconfig if available
    if [ -f "$KUBECONFIG" ]; then
        args="$args --kubeconfig=$KUBECONFIG"
    fi
    
    # Start Higress in background
    print_status "Executing: $HIGRESS_BIN serve $args"
    nohup "$HIGRESS_BIN" serve $args > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    
    # Wait for startup
    print_status "Waiting for Higress to start..."
    local started=false
    for i in {1..30}; do
        if check_running; then
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
    if check_running; then
        local pid=$(cat "$PID_FILE")
        print_success "Higress is running (PID: $pid)"
        
        # Check HTTP endpoint
        if curl -s http://localhost:8888/ready > /dev/null 2>&1; then
            print_success "HTTP server is responding on port 8888"
        else
            print_warning "HTTP server not responding on port 8888"
        fi
        
        # Show recent logs
        if [ -f "$LOG_FILE" ]; then
            print_status "Recent log entries:"
            tail -10 "$LOG_FILE"
        fi
    else
        print_warning "Higress is not running"
    fi
}

# Function to test endpoints
test_endpoints() {
    print_status "Testing Higress endpoints..."
    
    # Test readiness endpoint
    if curl -s http://localhost:8888/ready; then
        print_success "Readiness endpoint: OK"
    else
        print_error "Readiness endpoint: FAILED"
    fi
    
    # Test debug endpoint
    if curl -s http://localhost:8888/debug/configz | head -5; then
        print_success "Debug endpoint: OK"
    else
        print_error "Debug endpoint: FAILED"
    fi
}

# Function to show logs
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_status "Showing Higress logs (press Ctrl+C to exit):"
        tail -f "$LOG_FILE"
    else
        print_error "Log file not found: $LOG_FILE"
    fi
}

# Main script logic
case "${1:-start}" in
    start)
        check_prerequisites
        if check_running; then
            print_warning "Higress is already running"
            show_status
        else
            start_higress
        fi
        ;;
    stop)
        stop_higress
        ;;
    restart)
        stop_higress
        sleep 2
        check_prerequisites
        start_higress
        ;;
    force-restart)
        pkill -f "higress serve" 2>/dev/null || true
        rm -f "$PID_FILE"
        sleep 2
        check_prerequisites
        start_higress
        ;;
    status)
        show_status
        ;;
    test)
        test_endpoints
        ;;
    logs)
        show_logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|force-restart|status|test|logs}"
        echo ""
        echo "Commands:"
        echo "  start        - Start Higress component (default)"
        echo "  stop         - Stop Higress component"
        echo "  restart      - Restart Higress component"
        echo "  force-restart- Force restart (kill all processes)"
        echo "  status       - Show current status"
        echo "  test         - Test Higress endpoints"
        echo "  logs         - Show and follow logs"
        exit 1
        ;;
esac 