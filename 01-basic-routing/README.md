# 01-basic-routing: Basic HTTP Routing with Gateway API

This demo showcases the fundamental components of Kubernetes Gateway API and demonstrates basic HTTP routing to a single service.

## 📋 Overview

This is the foundational demo that introduces all core concepts of Gateway API:
- **GatewayClass**: Defines the controller implementation
- **Gateway**: Creates a load balancer entry point
- **HTTPRoute**: Configures routing rules
- **Service & Deployment**: Backend application

## 🎯 What You'll Learn

1. How to create a GatewayClass
2. How to create a Gateway with HTTP listener
3. How to route traffic using HTTPRoute
4. How to deploy and expose a backend service
5. How hostname-based routing works

## 📁 Files in This Demo

| File | Resource Type | Purpose |
|------|--------------|---------|
| `gateway_class.yaml` | GatewayClass | Defines that Envoy Gateway controls this class |
| `gateway.yaml` | Gateway | Creates a load balancer listening on port 80 |
| `svc_account.yaml` | ServiceAccount | Pod identity for the product service |
| `product-service-deploy.yaml` | Deployment | Deploys the product service pods |
| `product-service-svc.yaml` | Service | Exposes product service on port 3000 |
| `product-service-route.yaml` | HTTPRoute | Routes `www.example.com` to product-service |

## 🏗️ Architecture

```
Client (curl)
    │
    ├─ Host: www.example.com
    │
    ▼
┌─────────────────┐
│  GatewayClass   │  ← Managed by cluster operator
│  (name: eg)     │     Specifies Envoy Gateway as controller
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Gateway      │  ← Managed by cluster operator
│   (name: eg)    │     Listener: HTTP on port 80
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   HTTPRoute     │  ← Managed by app developer
│  (product-svc)  │     Hostname: www.example.com
└────────┬────────┘     Path: /
         │
         ▼
┌─────────────────┐
│    Service      │  ← Kubernetes Service
│ product-service │     Port: 3000
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Deployment    │  ← Backend pods
│ product-service │     Echo server responding with pod info
└─────────────────┘
```

## 🚀 Quick Start

### Option 1: Automated Demo

```bash
# From repository root
./run-demo.sh basic
```

### Option 2: Manual Deployment

```bash
# 1. Deploy all resources
kubectl apply -f 01-basic-routing/

# 2. Wait for pods to be ready
kubectl wait --for=condition=Ready pods --all --timeout=60s

# 3. Check Gateway status
kubectl get gateway eg

# 4. Test the endpoint
curl -H "Host: www.example.com" http://localhost:8080/
```

## 📝 Step-by-Step Walkthrough

### Step 1: Create GatewayClass

```bash
kubectl apply -f gateway_class.yaml
kubectl get gatewayclass
```

Expected output:
```
NAME   CONTROLLER                            ACCEPTED   AGE
eg     gateway.envoyproxy.io/gatewayclass-controller   True       5s
```

**What it does:** Tells Kubernetes that Envoy Gateway will manage any Gateway resources that reference this class.

### Step 2: Create Gateway

```bash
kubectl apply -f gateway.yaml
kubectl get gateway eg
```

Expected output:
```
NAME   CLASS   ADDRESS         PROGRAMMED   AGE
eg     eg      10.96.xxx.xxx   True         10s
```

**What it does:** Creates an Envoy Proxy load balancer listening on HTTP port 80.

### Step 3: Deploy Backend Application

```bash
# Apply ServiceAccount, Deployment, and Service
kubectl apply -f svc_account.yaml
kubectl apply -f product-service-deploy.yaml
kubectl apply -f product-service-svc.yaml

# Verify deployment
kubectl get pods
kubectl get svc product-service
```

**What it does:** Deploys an echo server that responds with request information (useful for testing).

### Step 4: Create HTTPRoute

```bash
kubectl apply -f product-service-route.yaml
kubectl get httproute
```

Expected output:
```
NAME                    HOSTNAMES              AGE
product-service-route   ["www.example.com"]    5s
```

**What it does:** Configures routing rule - requests to `www.example.com` go to `product-service`.

### Step 5: Test the Route

```bash
# Make a request
curl -H "Host: www.example.com" http://localhost:8080/
```

Expected response (JSON):
```json
{
  "path": "/",
  "host": "www.example.com",
  "method": "GET",
  "proto": "HTTP/1.1",
  "headers": {
    "Accept": ["*/*"],
    "User-Agent": ["curl/7.x.x"]
  },
  "namespace": "default",
  "ingress": "",
  "service": "",
  "pod": "product-service-xxxxxxxxx-xxxxx"
}
```

## 🔍 Understanding the Components

### GatewayClass

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

- **Purpose**: Defines which controller manages Gateways
- **Scope**: Cluster-scoped (not namespace)
- **Who manages**: Cluster operator
- **Analogy**: Like IngressClass in traditional Ingress

### Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: eg
spec:
  gatewayClassName: eg  # References the GatewayClass
  listeners:
    - name: http
      protocol: HTTP
      port: 80
```

- **Purpose**: Creates a load balancer instance
- **Scope**: Namespace-scoped
- **Who manages**: Cluster operator
- **Analogy**: Like a LoadBalancer Service

### HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: product-service-route
spec:
  parentRefs:
    - name: eg  # Attaches to Gateway named 'eg'
  hostnames:
    - "www.example.com"
  rules:
    - backendRefs:
        - name: product-service
          port: 3000
```

- **Purpose**: Defines routing rules
- **Scope**: Namespace-scoped
- **Who manages**: Application developer
- **Analogy**: Like Ingress rules

## 🧪 Testing Scenarios

### Test 1: Basic Request

```bash
curl -H "Host: www.example.com" http://localhost:8080/
```

Should return JSON with pod information.

### Test 2: With Different Paths

```bash
curl -H "Host: www.example.com" http://localhost:8080/api/products
curl -H "Host: www.example.com" http://localhost:8080/health
```

All paths under `/` are routed to the service.

### Test 3: Wrong Hostname (should fail)

```bash
curl -H "Host: wrong.example.com" http://localhost:8080/
```

Should return 404 because HTTPRoute only matches `www.example.com`.

### Test 4: View Response Headers

```bash
curl -v -H "Host: www.example.com" http://localhost:8080/
```

Shows all HTTP headers including those added by the Gateway.

## 🔧 Troubleshooting

### Gateway shows "Programmed: False"

```bash
# Check Gateway events
kubectl describe gateway eg

# Check Envoy Gateway controller logs
kubectl logs -n envoy-gateway-system deployment/envoy-gateway
```

### HTTPRoute not working

```bash
# Verify HTTPRoute status
kubectl describe httproute product-service-route

# Check if parentRef is correct
kubectl get httproute product-service-route -o yaml | grep -A 3 parentRefs
```

### Pod not receiving traffic

```bash
# Check if Service endpoints exist
kubectl get endpoints product-service

# Verify Service selector matches Pod labels
kubectl get pod -l app=product-service
```

### Can't access localhost:8080

```bash
# Verify kind cluster port mapping
docker ps | grep kindcontrol-plane

# Check if Gateway service exists
kubectl get svc -n envoy-gateway-system
```

## 📊 Verification Commands

```bash
# View all Gateway API resources
kubectl get gatewayclass,gateway,httproute

# Describe Gateway with full details
kubectl describe gateway eg

# Check backend pod logs
kubectl logs -l app=product-service

# View Service details
kubectl describe svc product-service
```

## 🎓 Key Concepts

### Role Separation

| Resource | Managed By | Scope |
|----------|-----------|-------|
| GatewayClass | Cluster Operator | Cluster |
| Gateway | Cluster Operator | Namespace |
| HTTPRoute | App Developer | Namespace |
| Service | App Developer | Namespace |

### Traffic Flow

1. Client sends request to `localhost:8080` with Host header `www.example.com`
2. kind port mapping forwards to Gateway (port 80)
3. Gateway matches HTTPRoute based on hostname
4. HTTPRoute forwards to Service based on rules
5. Service load balances to backend Pods
6. Echo server responds with request details

## 🧹 Cleanup

```bash
# Delete all resources in this demo
kubectl delete -f 01-basic-routing/

# Or use the cleanup script
./run-demo.sh cleanup
```

## ➡️ Next Steps

Now that you understand basic routing, explore advanced features:
1. [02-url-rewrite](../02-url-rewrite/) - URL path rewriting
2. [03-traffic-splitting](../03-traffic-splitting/) - Split traffic between services
3. [04-weighted-routing](../04-weighted-routing/) - Canary deployments

## 📚 Additional Resources

- [Gateway API Concepts](https://gateway-api.sigs.k8s.io/concepts/api-overview/)
- [HTTPRoute API Reference](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRoute)
- [Envoy Gateway Tasks](https://gateway.envoyproxy.io/latest/tasks/)

---

**Congratulations! 🎉** You've learned the basics of Kubernetes Gateway API routing.
