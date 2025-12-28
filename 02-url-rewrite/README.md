# 02-url-rewrite: URL Path Rewriting

This demo shows how to rewrite URL paths before they reach the backend service.

## 📋 Overview

URL rewriting allows you to modify the request path before forwarding to the backend. This is useful for:
- API versioning (hide versions from clients)
- Path normalization
- Legacy system integration
- Simplifying backend routing

## 🎯 What This Demo Does

- **Incoming Request**: `GET /get`
- **Rewritten To**: `GET /replace`
- **Backend Receives**: `/replace` (not `/get`)

## 📁 Files

| File | Purpose |
|------|---------|
| `rewrite-httproute.yaml` | HTTPRoute with URLRewrite filter |

## 🚀 Quick Start

### Run the Demo

```bash
# From repository root
./run-demo.sh rewrite
```

### Manual Deployment

```bash
# 1. Ensure basic routing is deployed
kubectl apply -f 01-basic-routing/gateway.yaml
kubectl apply -f 01-basic-routing/gateway_class.yaml
kubectl apply -f 01-basic-routing/product-service-deploy.yaml
kubectl apply -f 01-basic-routing/product-service-svc.yaml
kubectl apply -f 01-basic-routing/svc_account.yaml

# 2. Deploy URL rewrite route
kubectl apply -f 02-url-rewrite/rewrite-httproute.yaml

# 3. Test it
curl -H "Host: path.rewrite.example" http://localhost:8080/get
```

## 🔍 How It Works

### The HTTPRoute Configuration

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-filter-url-rewrite
spec:
  parentRefs:
    - name: eg
  hostnames:
    - path.rewrite.example
  rules:
    - matches:
      - path:
          value: "/get"
      filters:
      - type: URLRewrite
        urlRewrite:
          path:
            type: ReplacePrefixMatch
            replacePrefixMatch: /replace
      backendRefs:
      - name: product-service
        port: 3000
```

### Key Components

1. **Hostname Match**: `path.rewrite.example`
2. **Path Match**: `/get`
3. **Filter Type**: `URLRewrite`
4. **Rewrite Action**: Replace `/get` with `/replace`
5. **Backend**: `product-service` on port 3000

## 🧪 Testing

### Test 1: Request to /get (gets rewritten)

```bash
curl -H "Host: path.rewrite.example" http://localhost:8080/get
```

Response shows `"path": "/replace"` - proving the rewrite worked!

### Test 2: Request to different path (no rewrite)

```bash
curl -H "Host: path.rewrite.example" http://localhost:8080/other
```

Returns 404 because only `/get` is matched and rewritten.

### Test 3: Verbose output

```bash
curl -v -H "Host: path.rewrite.example" http://localhost:8080/get
```

Shows full request/response flow.

## 📊 Use Cases

### 1. API Versioning

Hide version from clients:
```
Client requests: /users
Backend receives: /v2/users
```

### 2. Path Normalization

Standardize paths:
```
Client requests: /api
Backend receives: /api/v1
```

### 3. Legacy System Integration

Modern API to legacy backend:
```
Client requests: /products
Backend receives: /legacy/prod.php
```

### 4. Microservices Routing

Simplify client paths:
```
Client requests: /checkout
Backend receives: /payment/process
```

## 🔧 Advanced Rewrite Types

### Replace Full Path

```yaml
filters:
- type: URLRewrite
  urlRewrite:
    path:
      type: ReplaceFullPath
      replaceFullPath: /new/path
```

### Replace Prefix

```yaml
filters:
- type: URLRewrite
  urlRewrite:
    path:
      type: ReplacePrefixMatch
      replacePrefixMatch: /api/v2
```

### Hostname Rewrite

```yaml
filters:
- type: URLRewrite
  urlRewrite:
    hostname: backend.internal.svc.cluster.local
```

## 🧹 Cleanup

```bash
kubectl delete httproute http-filter-url-rewrite
```

## ➡️ Next Steps

- [03-traffic-splitting](../03-traffic-splitting/) - Split traffic between services
- [04-weighted-routing](../04-weighted-routing/) - Weighted distribution

## 📚 Resources

- [Gateway API Request Redirect](https://gateway-api.sigs.k8s.io/guides/http-redirect-rewrite/)
- [HTTPRoute Filters](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRouteFilter)

---

**URL rewriting enables flexible routing! ✨**
