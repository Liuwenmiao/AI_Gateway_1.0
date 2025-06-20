#!/bin/bash

# Quick Higress Test Startup - Simplified Version
# Based on your current running configuration

# Kill any existing Higress processes
echo "🔍 Checking for existing Higress processes..."
pkill -f "higress serve" 2>/dev/null && echo "✅ Stopped existing Higress instances" || echo "ℹ️  No existing instances found"

# Wait a moment
sleep 2

# Start Higress with your current configuration
echo "🚀 Starting Higress for testing..."
nohup ./bin/higress serve \
    --httpAddress=:8888 \
    --grpcAddress=:15051 \
    --ingressClass=higress-local \
    --debug=true \
    --enableStatus=true \
    --kubeconfig=$HOME/.kube/config \
    --gatewaySelectorKey=higress \
    --gatewaySelectorValue=higress-system-higress-gateway \
    > higress-test.log 2>&1 &

# Store PID
PID=$!
echo $PID > higress.pid
echo "📝 Higress started with PID: $PID"

# Wait for startup
echo "⏳ Waiting for Higress to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8888/ready > /dev/null 2>&1; then
        echo "✅ Higress is ready!"
        echo "🌐 HTTP Server: http://localhost:8888"
        echo "📊 gRPC Server: localhost:15051"
        echo "📋 Log file: higress-test.log"
        echo ""
        echo "🧪 Test endpoints:"
        echo "   curl http://localhost:8888/ready"
        echo "   curl http://localhost:8888/debug/configz"
        echo ""
        echo "📜 View logs: tail -f higress-test.log"
        echo "🛑 Stop: kill $PID"
        exit 0
    fi
    sleep 2
    echo -n "."
done

echo "❌ Higress failed to start within 60 seconds"
echo "📋 Check logs: tail -20 higress-test.log"
tail -20 higress-test.log
exit 1 