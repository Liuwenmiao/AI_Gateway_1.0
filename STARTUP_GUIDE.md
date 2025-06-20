# 🚀 Higress AI Gateway - Test Environment Startup Guide

## 📊 Current Status

Based on your logs, the Higress component is **already running** with the following configuration:
- **HTTP Server**: `localhost:8888` 
- **gRPC Server**: `localhost:15051`
- **Ingress Class**: `higress-local`
- **Status**: ✅ All caches synced and server ready

## 🛠️ Startup Scripts Available

### 1. Quick Start (Recommended for Testing)
```bash
./higress-quick-start.sh
```
- Simple one-command startup
- Matches your current configuration
- Perfect for quick testing sessions

### 2. Advanced Management Script
```bash
./start-higress-test.sh [command]
```
Available commands:
- `start` - Start Higress (default)
- `stop` - Stop Higress
- `restart` - Restart Higress  
- `status` - Show current status
- `test` - Test endpoints
- `logs` - Show and follow logs

## 🧪 Testing Your Setup

### Basic Health Check
```bash
# Test readiness
curl http://localhost:8888/ready

# Test debug endpoint
curl http://localhost:8888/debug/configz
```

### AI Gateway Testing (with your existing proxy)
Your AI Gateway is accessible at:
```bash
curl -X POST http://192.168.49.1:8889/compatible-mode/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-49dc7c806e0a4ad08f076b22c4fbee86" \
  -d '{
    "model": "qwen-turbo",
    "messages": [{"role": "user", "content": "Hello from Higress!"}],
    "max_tokens": 100
  }'
```

## 🏗️ Manual Startup (Direct Command)

If you prefer to start manually:
```bash
./bin/higress serve \
    --httpAddress=:8888 \
    --grpcAddress=:15051 \
    --ingressClass=higress-local \
    --debug=true \
    --enableStatus=true \
    --kubeconfig=$HOME/.kube/config \
    --gatewaySelectorKey=higress \
    --gatewaySelectorValue=higress-system-higress-gateway
```

## 📋 Configuration Details

### Server Ports
- **8888**: HTTP debug/monitoring interface
- **15051**: gRPC discovery service (XDS)
- **8889**: Your AI proxy (separate service)

### Key Features Enabled
- ✅ Debug mode for development
- ✅ Status reporting
- ✅ Kubernetes integration
- ✅ Gateway API support
- ✅ Service discovery

## 🔧 Troubleshooting

### If Startup Fails
1. Check if ports are available:
   ```bash
   netstat -ln | grep -E ":(8888|15051)"
   ```

2. View logs:
   ```bash
   tail -f higress-test.log
   ```

3. Check Kubernetes connection:
   ```bash
   kubectl cluster-info
   ```

### Common Issues
- **Port conflicts**: Change ports in startup script
- **Kubeconfig issues**: Verify `~/.kube/config` exists
- **Permission errors**: Check binary permissions

## 🎯 Next Steps

1. **Start Testing**: Use `./higress-quick-start.sh`
2. **Monitor Logs**: `tail -f higress-test.log`
3. **Test Endpoints**: Use the curl commands above
4. **Deploy Configs**: Apply your YAML configurations

## 📞 Quick Commands Reference

```bash
# Start quickly
./higress-quick-start.sh

# Check status
./start-higress-test.sh status

# View logs
./start-higress-test.sh logs

# Test endpoints
./start-higress-test.sh test

# Stop service
./start-higress-test.sh stop
```

---

**🎉 Your Higress AI Gateway is ready for testing!** 