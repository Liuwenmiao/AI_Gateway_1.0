# 🚀 Higress AI Gateway - Minikube Test Environment

## 📊 Current Setup

✅ **Detected**: You're using **minikube** for local Kubernetes testing  
✅ **Status**: Minikube is currently stopped  
✅ **Ready**: Minikube-optimized startup scripts created  

## 🎯 Recommended: Quick Start for Minikube

**One command to start everything:**
```bash
./quick-start-minikube.sh
```

This will:
- ✅ Start minikube (if stopped)
- ✅ Wait for cluster readiness
- ✅ Start Higress component
- ✅ Show all connection details
- ✅ Display test commands

## 🛠️ Advanced Minikube Management

For full control, use the minikube-optimized script:

```bash
# Start minikube and Higress
./start-higress-minikube.sh start

# Check status of both
./start-higress-minikube.sh status

# Show minikube-specific test commands
./start-higress-minikube.sh test

# View logs
./start-higress-minikube.sh logs

# Stop Higress (keep minikube running)
./start-higress-minikube.sh stop

# Stop everything including minikube
./start-higress-minikube.sh minikube-stop
```

## 🧪 Testing Your Minikube Setup

### 1. Basic Health Checks
```bash
# Test Higress readiness
curl http://localhost:8888/ready

# Check cluster status
kubectl get nodes
kubectl get pods -A

# Open minikube dashboard
minikube dashboard
```

### 2. Deploy Test Applications
```bash
# Deploy sample ingress application
kubectl apply -f samples/quickstart.yaml

# Check deployment
kubectl get pods
kubectl get ingress
```

### 3. Access Services
```bash
# Get minikube IP
minikube ip

# Access via NodePort (if services are deployed)
kubectl get svc -A

# Use port forwarding for local access
kubectl port-forward -n higress-system svc/higress-gateway 8080:80
```

## 🌐 Minikube Networking

### Access Patterns
- **Higress Management**: `http://localhost:8888`
- **Minikube Cluster**: `http://$(minikube ip)`
- **Port Forwarding**: For local service access
- **NodePort**: For external access via minikube IP

### Key Differences from Other Setups
- **IP Address**: Minikube uses a separate VM IP
- **Service Access**: Often requires port forwarding or NodePort
- **LoadBalancer**: Minikube tunnel needed for LoadBalancer services

## 📋 Configuration Details

### Minikube Optimizations
- **Driver**: Docker (recommended)
- **Memory**: 4GB allocated
- **CPUs**: 2 cores allocated
- **Ingress Class**: `higress` (standard)

### Higress Configuration
- **HTTP Interface**: `localhost:8888`
- **gRPC Interface**: `localhost:15051`
- **Kubeconfig**: Uses standard minikube config
- **Debug Mode**: Enabled for development

## 🔧 Troubleshooting

### Minikube Issues
```bash
# Check minikube status
minikube status

# View minikube logs
minikube logs

# Restart minikube if needed
minikube stop
minikube start

# Reset minikube completely
minikube delete
minikube start
```

### Higress Issues
```bash
# Check Higress logs
tail -f higress-minikube.log

# Test connectivity
curl -v http://localhost:8888/ready

# Check process
ps aux | grep higress
```

### Common Minikube Problems
- **Docker Issues**: Ensure Docker is running
- **Resource Limits**: Increase memory/CPU if needed
- **Network Conflicts**: Check for port conflicts
- **Driver Issues**: Try different drivers if needed

## 🚀 Production Deployment

### Moving from Minikube to Production
1. **Test thoroughly** in minikube first
2. **Export configurations**: `kubectl get ingress -o yaml`
3. **Adapt networking** for production cluster
4. **Scale resources** as needed
5. **Setup monitoring** and logging

### Minikube vs Production Differences
| Feature | Minikube | Production |
|---------|----------|------------|
| Networking | VM-based | Cloud native |
| LoadBalancer | Tunnel required | Native support |
| Storage | hostPath | Persistent volumes |
| Scale | Single node | Multi-node |
| Access | Local only | Internet facing |

## 📞 Quick Reference

```bash
# Essential minikube commands
minikube start              # Start cluster
minikube stop               # Stop cluster  
minikube status             # Check status
minikube ip                 # Get cluster IP
minikube dashboard          # Open web UI
minikube tunnel             # Enable LoadBalancer

# Higress with minikube
./quick-start-minikube.sh   # Start everything
./start-higress-minikube.sh status  # Check status
kubectl get pods -A         # View all pods
kubectl apply -f samples/   # Deploy samples
```

---

**🎉 Perfect for Minikube! Your local testing environment is ready.**

**Next Step**: Run `./quick-start-minikube.sh` to get started! 