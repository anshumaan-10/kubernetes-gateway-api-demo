#!/bin/bash
# Complete setup script for Kubernetes Gateway API Demo

set -e

echo "========================================="
echo "Kubernetes Gateway API Demo Setup"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo -e "${YELLOW}kind is not installed. Installing...${NC}"
    # For macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install kind
    else
        echo "Please install kind manually: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        exit 1
    fi
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}kubectl is not installed. Please install it first${NC}"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}helm is not installed. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install helm
    else
        echo "Please install helm manually: https://helm.sh/docs/intro/install/"
        exit 1
    fi
fi

# Create kind cluster with custom config
echo -e "${BLUE}Creating kind cluster with port mappings...${NC}"
if kind get clusters | grep -q gateway-demo; then
    echo -e "${YELLOW}Cluster 'gateway-demo' already exists. Deleting...${NC}"
    kind delete cluster --name gateway-demo
fi

kind create cluster --config kind-config.yaml

echo -e "${GREEN}✓ Kind cluster created${NC}"

# Wait for cluster to be ready
echo -e "${BLUE}Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=60s

echo -e "${GREEN}✓ Cluster is ready${NC}"

# Install Envoy Gateway
echo -e "${BLUE}Installing Envoy Gateway...${NC}"
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.2.1 \
  -n envoy-gateway-system \
  --create-namespace

echo -e "${BLUE}Waiting for Envoy Gateway to be ready...${NC}"
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

echo -e "${GREEN}✓ Envoy Gateway installed and ready${NC}"

echo ""
echo -e "${GREEN}========================================="
echo "Setup Complete!"
echo "=========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Deploy basic routing:      ./run-demo.sh basic"
echo "2. Deploy URL rewrite:        ./run-demo.sh rewrite"
echo "3. Deploy traffic splitting:  ./run-demo.sh splitting"
echo "4. Deploy weighted routing:   ./run-demo.sh weighted"
echo ""
echo "Or run all demos in sequence: ./run-demo.sh all"
