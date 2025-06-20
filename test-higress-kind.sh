#!/bin/bash

# 🧪 Higress Kind Cluster - Simplified Testing Script
# This script provides direct access to backend services for testing

echo "🚀 Higress Kind Cluster - Test Environment"
echo "=========================================="

# Check current context
CURRENT_CONTEXT=$(kubectl config current-context)
echo "📍 Current Context: $CURRENT_CONTEXT"

if [ "$CURRENT_CONTEXT" != "kind-higress-ai" ]; then
    echo "⚠️  Switching to kind-higress-ai context..."
    kubectl config use-context kind-higress-ai
fi

echo ""
echo "📊 System Status:"
echo "----------------"

# Check local controller
if curl -s http://localhost:8888/ready > /dev/null; then
    echo "✅ Local Higress Controller: Running (localhost:8888)"
else
    echo "❌ Local Higress Controller: Not running"
    echo "   Start with: ./start-local-controller-kind.sh"
fi

# Check Java backend
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ Java Backend (Console): Running (localhost:8080)"
else
    echo "❌ Java Backend (Console): Not running"
    echo "   Start with: ./manage-java-backend.sh start"
fi

# Check pods
echo "✅ Backend Pods:"
kubectl get pods --no-headers | grep -E "(foo-app|bar-app)" | awk '{print "   - " $1 ": " $3}'

echo ""
echo "🧪 Available Tests:"
echo "------------------"
echo "1. Higress Console (Java Backend):"
echo "   • Web UI: http://localhost:8080"
echo "   • API: http://localhost:8080/api/v1/"
echo ""
echo "2. Direct Backend Access:"
echo "   • foo-app: curl http://localhost:5678"
echo "   • bar-app: curl http://localhost:5679"
echo ""
echo "3. Kubernetes Service Access:"
echo "   • kubectl port-forward svc/foo-service 8080:5678"
echo "   • kubectl port-forward svc/bar-service 8081:5678"
echo ""
echo "4. Controller API:"
echo "   • curl http://localhost:8888/ready"
echo "   • curl http://localhost:8888/stats/prometheus"
echo ""

# Test direct access
echo "🔍 Quick Test:"
echo "-------------"
echo -n "foo-app response: "
timeout 3 curl -s http://localhost:5678 2>/dev/null || echo "Not accessible (run setup first)"
echo -n "bar-app response: "
timeout 3 curl -s http://localhost:5679 2>/dev/null || echo "Not accessible (run setup first)"

echo ""
echo "📝 To set up port forwards:"
echo "kubectl port-forward pod/foo-app 5678:5678 &"
echo "kubectl port-forward pod/bar-app 5679:5678 &" 