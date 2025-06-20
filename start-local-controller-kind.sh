#!/bin/bash

# 🚀 Start Local Higress Controller for Kind Cluster

echo "🔧 Starting Local Higress Controller for Kind Cluster..."

# Switch to kind context
kubectl config use-context kind-higress-ai

# Stop any existing controller
pkill -f "higress serve" 2>/dev/null
rm -f higress-kind.pid

# Start local controller
echo "🚀 Starting local controller..."
nohup ./bin/higress serve \
    --httpAddress=:8888 \
    --grpcAddress=:15051 \
    --ingressClass=higress \
    --debug=true \
    --enableStatus=true \
    --kubeconfig=$HOME/.kube/config \
    --gatewaySelectorKey=higress \
    --gatewaySelectorValue=higress-system-higress-gateway \
    > higress-kind.log 2>&1 &

echo $! > higress-kind.pid

# Wait for startup
sleep 3

# Check status
if curl -s http://localhost:8888/ready > /dev/null; then
    echo "✅ Local controller started successfully!"
    echo "📍 HTTP API: http://localhost:8888"
    echo "📍 gRPC API: localhost:15051" 
    echo "📍 Log file: higress-kind.log"
    echo "📍 PID file: higress-kind.pid"
    echo ""
    echo "🧪 Run tests with: ./test-higress-kind.sh"
else
    echo "❌ Controller failed to start. Check higress-kind.log"
fi 