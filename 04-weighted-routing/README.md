# 04-weighted-routing: Weighted Traffic Distribution

This demo demonstrates weighted traffic routing for canary deployments and gradual rollouts.

## 📋 Overview

Weighted routing allows you to control the percentage of traffic sent to each backend service. This is essential for:
- **Canary deployments** - Test new versions with limited traffic
- **Blue-green deployments** - Gradual traffic shifting
- **A/B testing** - Control experiment exposure
- **Feature flags** - Progressive feature rollouts

## 🎯 What This Demo Does

- **80% traffic** → `product-service` (stable version)
- **20% traffic** → `user-service` (canary version)
- Proportional load balancing based on weights

## 📁 Files

| File | Purpose |
|------|---------|
| `httproute_weighted.yaml` | HTTPRoute with weight-based traffic distribution |

## 🚀 Quick Start

### Run the Demo

```bash
# From repository root
./run-demo.sh weighted
```

### Manual Deployment

```bash
# 1. Deploy base resources
kubectl apply -f 01-basic-routing/gateway.yaml
kubectl apply -f 01-basic-routing/gateway_class.yaml
kubectl apply -f 01-basic-routing/svc_account.yaml
kubectl apply -f 01-basic-routing/product-service-deploy.yaml
kubectl apply -f 01-basic-routing/product-service-svc.yaml

# 2. Deploy second service (canary)
kubectl apply -f 03-traffic-splitting/user-service/

# 3. Deploy weighted route
kubectl apply -f 04-weighted-routing/httproute_weighted.yaml

# 4. Test distribution
for i in {1..20}; do
  curl -s -H "Host: backends.example" http://localhost:8080/ | jq -r '.pod'
done | sort | uniq -c
```

## 🏗️ Architecture

```
100 Requests
     │
     ▼
 Gateway (eg)
     │
     ▼
HTTPRoute (weighted-route)
     │
     ├────────────────────┐
     │                    │
     ▼ (weight: 8)        ▼ (weight: 2)
product-service      user-service
    80%                  20%
(stable)             (canary)
```

## 🔍 How It Works

### HTTPRoute Configuration

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: weighted-route
spec:
  parentRefs:
  - name: eg
  hostnames:
  - backends.example
  rules:
  - backendRefs:
    - name: product-service
      port: 3000
      weight: 8  # 80% traffic
    - name: user-service
      port: 3000
      weight: 2  # 20% traffic
```

**Key Points:**
- Weights are relative (not percentages)
- Total: 8 + 2 = 10
- product-service gets: 8/10 = 80%
- user-service gets: 2/10 = 20%

## 🧪 Testing

### Test 1: Verify Weight Distribution

```bash
# Make 20 requests and count distribution
for i in {1..20}; do
  curl -s -H "Host: backends.example" http://localhost:8080/ | jq -r '.pod'
done | sort | uniq -c
```

Expected output (approximately):
```
16 product-service-xxxxx-xxxxx  (80%)
 4 user-service-xxxxx-xxxxx     (20%)
```

### Test 2: Larger Sample Size

```bash
# 100 requests for more accurate distribution
for i in {1..100}; do
  curl -s -H "Host: backends.example" http://localhost:8080/ | jq -r '.pod'
done | sort | uniq -c
```

Should show ~80 vs ~20 requests.

### Test 3: Monitor in Real-Time

```bash
# In one terminal, watch pods
kubectl get pods -w

# In another terminal, send requests
while true; do
  curl -s -H "Host: backends.example" http://localhost:8080/ >/dev/null
  sleep 0.1
done
```

## 📊 Common Weight Patterns

### Canary Deployment (5% canary)

```yaml
backendRefs:
- name: stable
  weight: 95
- name: canary
  weight: 5
```

### Gradual Rollout (20% new version)

```yaml
backendRefs:
- name: v1
  weight: 80
- name: v2
  weight: 20
```

### A/B Testing (50/50)

```yaml
backendRefs:
- name: variant-a
  weight: 50
- name: variant-b
  weight: 50
```

### Blue-Green (full cutover)

```yaml
# Initially: 100% blue
backendRefs:
- name: blue
  weight: 100
- name: green
  weight: 0

# After validation: 100% green
backendRefs:
- name: blue
  weight: 0
- name: green
  weight: 100
```

## 🎓 Canary Deployment Strategy

### Step-by-Step Canary Rollout

```bash
# Step 1: Deploy canary with 10% traffic
weight: 90 (stable), 10 (canary)

# Step 2: Monitor metrics, increase to 25%
weight: 75 (stable), 25 (canary)

# Step 3: If healthy, increase to 50%
weight: 50 (stable), 50 (canary)

# Step 4: Final cutover to 100%
weight: 0 (stable), 100 (canary)

# Step 5: Remove old version
# Delete old deployment
```

### Example: Progressive Rollout

```bash
# Start with 10% canary
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: weighted-route
spec:
  parentRefs:
  - name: eg
  hostnames:
  - backends.example
  rules:
  - backendRefs:
    - name: product-service
      port: 3000
      weight: 90
    - name: user-service
      port: 3000
      weight: 10
