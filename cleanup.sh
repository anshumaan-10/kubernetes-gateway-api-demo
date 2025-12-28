#!/bin/bash
# Cleanup script for Kubernetes Gateway API Demo

echo "Cleaning up all resources..."

# Delete all demo resources
kubectl delete httproute --all 2>/dev/null || true
kubectl delete gateway --all 2>/dev/null || true
kubectl delete deployment --all 2>/dev/null || true
kubectl delete svc --all 2>/dev/null || true
kubectl delete sa --all 2>/dev/null || true
kubectl delete gatewayclass --all 2>/dev/null || true

# Stop any port-forwards
pkill -f "port-forward.*envoy-gateway" 2>/dev/null || true

# Delete kind cluster
echo "Deleting kind cluster..."
kind delete cluster --name gateway-demo 2>/dev/null || true

echo "✓ Cleanup complete!"
