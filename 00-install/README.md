# 00-install: Envoy Gateway Installation

This folder contains instructions for installing the Envoy Gateway controller.

## 🚀 Automated Installation

```bash
cd ..
./setup.sh
```

## 📝 Manual Installation

### Install Envoy Gateway with Helm

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.2.1 \
  -n envoy-gateway-system \
  --create-namespace
```

### Verify Installation

```bash
kubectl wait --timeout=5m \
  -n envoy-gateway-system \
  deployment/envoy-gateway \
  --for=condition=Available
```

### Check Components

```bash
kubectl get all -n envoy-gateway-system
```

## ✅ Verification

```bash
# Check CRDs
kubectl get crd | grep gateway

# Verify pod
kubectl get pods -n envoy-gateway-system
```

## ➡️ Next Steps

Proceed to [01-basic-routing](../01-basic-routing/)
