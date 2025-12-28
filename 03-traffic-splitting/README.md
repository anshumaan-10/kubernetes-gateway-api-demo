# 03-traffic-splitting: Equal Traffic Distribution

This demo shows how to split traffic equally between multiple backend services using round-robin load balancing.

## 📋 Overview

Traffic splitting distributes requests across multiple services without specifying weights. The Gateway uses round-robin to distribute traffic evenly.

**Use Cases:**
- A/B testing with equal distribution
- Multi-service architectures
- Blue-green deployments (50/50)
- Load distribution across microservices

## 🎯 What This Demo Does

- 50% traffic → `product-service`
- 50% traffic → `user-service`
- Round-robin distribution (alternating requests)

## 📁 Files

| File | Purpose |
|------|---------|
| `httproute_traffic_splitting.yaml` | HTTPRoute with multiple backends |
| `user-service/user-service-deploy.yaml` | Second service deployment |
| `user-service/user-service-svc.yaml` | Second service |
| `user-service/user-service-sa.yaml` | ServiceAccount for user service |

## 🚀 Quick Start

### Run the Demo

```bash
# From repository root
./run-demo.sh splitting
```

### Manual Deployment

```bash
# 1. Deploy base resources
kubectl apply -f 01-basic-routing/gateway.yaml
kubectl apply -f 01-basic-routing/gateway_class.yaml
kubectl apply -f 01-basic-routing/svc_account.yaml
kubectl apply -f 01-basic-routing/product-service-deploy.yaml
kubectl apply -f 01-basic-routing/product-service-svc.yaml

# 2. Deploy second service
kubectl apply -f 03-traffic-splitting/user-service/

# 3. Deploy traffic splitting route
kubectl apply -f 03-traffic-splitting/httproute_traffic_splitting.yaml

# 4. Test it
for i in {1..10}; do
  curl -s -H "Host: backends.example" http://localhost:8080/ | jq -r '.pod'
done
```

## 🏗️ Architecture

```
Client Request (backends.example)
         │
         ▼
    Gateway (eg)
         │
         ▼
  HTTPRoute (multi-service-route)
         │
    ┌────┴────┐
    │         │
    ▼         ▼
product-   user-
service    service
 (50%)      (50%)
```

## 🔍 How It Works

### HTTPRoute Configuration

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: multi-service-route
spec:
  parentRefs:
  - name: eg
  hostnames:
  - backends.example
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: product-service
      port: 3000
    - name: user-service
      port: 3000
```

**Key Point:** Multiple `backendRefs` without weights = equal distribution.

## 🧪 Testing

### Test 1: See Round-Robin in Action

```bash
for i in {1..10}; do
  echo "Request $i:"
  curl -s -H "Host: backends.example" http://localhost:8080/ | jq -r '.pod'
done
```

Expected output alternates between:
```
product-service-xxxxx-xxxxx
user-service-xxxxx-xxxxx
product-service-xxxxx-xxxxx
user-service-xxxxx-xxxxx
...
```

### Test 2: Count Distribution

```bash
for i in {1..20}; do
  curl -s -H "Host: backends.example" http://localhost:8080/ | jq -r '.pod'
done | sort | uniq -c
```

Should show approximately equal counts.

### Test 3: Full Response

```bash
curl -H "Host: backends.example" http://localhost:8080/ | jq .
```

## 📊 Traffic Distribution

```
100 Requests
    ↓
┌───┴───┐
│Gateway│
└───┬───┘
    │
    ├─→ product-service (≈50 requests)
    └─→ user-service    (≈50 requests)
```

## 🎓 Comparison with Weighted Routing

| Feature | Traffic Splitting | Weighted Routing |
|---------|------------------|------------------|
| Distribution | Equal (50/50) | Configurable (e.g., 80/20) |
| Weights | Not specified | Explicit weights |
| Use Case | Equal A/B testing | Canary deployments |
| Configuration | `backendRefs` only | `backendRefs` with `weight` |

## 🔧 Scaling Services

```bash
# Scale product-service to 3 replicas
kubectl scale deployment product-service --replicas=3

# Scale user-service to 2 replicas
kubectl scale deployment user-service --replicas=2

# Traffic still 50/50 at service level
# But load balances across pods within each service
```

## 🐛 Troubleshooting

### Traffic not splitting

```bash
# Check both services have endpoints
kubectl get endpoints product-service user-service

# Verify HTTPRoute shows both backends
kubectl describe httproute multi-service-route
```

### Only seeing one service

```bash
# Check if both deployments are running
kubectl get pods -l 'app in (product-service,user-service)'

# Verify both services exist
kubectl get svc product-service user-service
```

## 🧹 Cleanup

```bash
kubectl delete -f 03-traffic-splitting/
```

## ➡️ Next Steps

- [04-weighted-routing](../04-weighted-routing/) - Control traffic percentages for canary deployments

## 📚 Resources

- [Gateway API Traffic Splitting](https://gateway-api.sigs.k8s.io/guides/traffic-splitting/)
- [HTTPRoute backendRefs](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPBackendRef)

---

**Equal distribution made simple! ⚖️**
