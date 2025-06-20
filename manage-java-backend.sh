#!/bin/bash

# 🚀 Higress Console Java Backend Management Script

BACKEND_DIR="./higress-console/backend"
LOG_FILE="$BACKEND_DIR/console.log"
JAR_FILE="$BACKEND_DIR/console/target/higress-console.jar"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

check_backend_running() {
    if curl -s http://localhost:8080 > /dev/null; then
        return 0
    else
        return 1
    fi
}

start_backend() {
    if check_backend_running; then
        print_warning "Java backend is already running on port 8080"
        return 0
    fi
    
    print_status "Starting Higress Console Java Backend..."
    
    if [ ! -f "$JAR_FILE" ]; then
        print_error "JAR file not found: $JAR_FILE"
        print_status "Building backend..."
        cd "$BACKEND_DIR" && ./build.sh && cd ../..
    fi
    
    cd "$BACKEND_DIR"
    nohup ./start.sh --local > console.log 2>&1 &
    PID=$!
    cd ../..
    
    print_status "Backend started with PID: $PID"
    print_status "Waiting for backend to initialize..."
    
    for i in {1..30}; do
        if check_backend_running; then
            print_success "Java backend started successfully!"
            print_success "🌐 Access: http://localhost:8080"
            return 0
        fi
        sleep 1
    done
    
    print_error "Backend failed to start within 30 seconds"
    return 1
}

stop_backend() {
    print_status "Stopping Java backend..."
    
    PID=$(ps aux | grep "higress-console.jar" | grep -v grep | awk '{print $2}')
    if [ -n "$PID" ]; then
        kill $PID
        print_success "Backend stopped (PID: $PID)"
    else
        print_warning "Backend not running"
    fi
}

status_backend() {
    echo "📊 Java Backend Status:"
    echo "======================"
    
    if check_backend_running; then
        print_success "✅ Running on port 8080"
        
        PID=$(ps aux | grep "higress-console.jar" | grep -v grep | awk '{print $2}')
        if [ -n "$PID" ]; then
            echo "   📍 Process ID: $PID"
        fi
        
        echo "   📍 Access URL: http://localhost:8080"
        echo "   📍 Log file: $LOG_FILE"
        
    else
        print_error "❌ Not running"
    fi
}

show_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo "📋 Backend Logs (last 20 lines):"
        echo "================================"
        tail -20 "$LOG_FILE"
    else
        print_error "Log file not found: $LOG_FILE"
    fi
}

test_backend() {
    echo "🧪 Testing Java Backend:"
    echo "========================"
    
    echo -n "Health check: "
    if check_backend_running; then
        echo "✅ OK"
    else
        echo "❌ Failed"
        return 1
    fi
    
    echo -n "Web interface: "
    if curl -s http://localhost:8080 | grep -q "Higress Console"; then
        echo "✅ OK"
    else
        echo "❌ Failed"
    fi
    
    echo ""
    echo "🌐 Available endpoints:"
    echo "   • Console UI: http://localhost:8080"
    echo "   • API Base: http://localhost:8080/api/v1/"
}

case "$1" in
    start)
        start_backend
        ;;
    stop)
        stop_backend
        ;;
    restart)
        stop_backend
        sleep 2
        start_backend
        ;;
    status)
        status_backend
        ;;
    logs)
        show_logs
        ;;
    test)
        test_backend
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|test}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the Java backend"
        echo "  stop    - Stop the Java backend"
        echo "  restart - Restart the Java backend"
        echo "  status  - Show backend status"
        echo "  logs    - Show backend logs"
        echo "  test    - Test backend functionality"
        exit 1
        ;;
esac 