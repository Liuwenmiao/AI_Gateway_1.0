#!/bin/bash

# 🚀 Higress + Minikube Quick Start
# One-command startup for minikube testing

set -e

echo "🔍 Checking minikube status..."

# Start minikube if not running
if ! minikube status | grep -q "host: Running"; then
    echo "🚀 Starting minikube..."
    minikube start --driver=docker --memory=4096 --cpus=2
    echo "⏳ Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    echo "✅ Minikube is ready!"
else
    echo "✅ Minikube is already running"
fi

# Get minikube IP
MINIKUBE_IP=$(minikube ip)
echo "📍 Minikube IP: $MINIKUBE_IP"

# Stop any existing Higress
echo "🔄 Stopping any existing Higress processes..."
pkill -f "higress serve" 2>/dev/null || true
rm -f higress-minikube.pid
sleep 2

# Start Higress
echo "🚀 Starting Higress for minikube..."
nohup ./bin/higress serve \
    --httpAddress=:8888 \
    --grpcAddress=:15051 \
    --ingressClass=higress \
    --debug=true \
    --enableStatus=true \
    --kubeconfig=$HOME/.kube/config \
    --gatewaySelectorKey=higress \
    --gatewaySelectorValue=higress-system-higress-gateway \
    > higress-minikube.log 2>&1 &

# Store PID
PID=$!
echo $PID > higress-minikube.pid
echo "📝 Higress started with PID: $PID"

# Wait for startup
echo "⏳ Waiting for Higress to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8888/ready > /dev/null 2>&1; then
        echo ""
        echo "🎉 SUCCESS! Higress is ready for minikube testing!"
        echo ""
        echo "📊 Status:"
        echo "   🌐 Minikube IP: $MINIKUBE_IP"
        echo "   🔧 Higress HTTP: http://localhost:8888"
        echo "   📡 Higress gRPC: localhost:15051"
        echo "   📋 Log file: higress-minikube.log"
        echo ""
        echo "🧪 Quick Tests:"
        echo "   curl http://localhost:8888/ready"
        echo "   kubectl get pods -A"
        echo "   minikube dashboard"
        echo ""
        echo "📦 Deploy Sample:"
        echo "   kubectl apply -f samples/quickstart.yaml"
        echo ""
        echo "🛑 Stop Everything:"
        echo "   ./start-higress-minikube.sh stop"
        echo "   minikube stop"
        echo ""
        echo "📜 View Logs:"
        echo "   tail -f higress-minikube.log"
        exit 0
    fi
    sleep 2
    echo -n "."
done

echo ""
echo "❌ Higress failed to start within 60 seconds"
echo "📋 Check logs: tail -20 higress-minikube.log"
tail -20 higress-minikube.log
exit 1 