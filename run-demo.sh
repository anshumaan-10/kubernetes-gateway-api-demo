#!/bin/bash
# Demo runner script for Kubernetes Gateway API demonstrations

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DEMO_TYPE=$1

# Function to wait for pods to be ready
wait_for_pods() {
    local namespace=${1:-default}
    echo -e "${BLUE}Waiting for pods in namespace ${namespace} to be ready...${NC}"
    kubectl wait --for=condition=Ready pods --all -n ${namespace} --timeout=60s 2>/dev/null || true
}

# Function to get gateway address
get_gateway_address() {
    # For kind cluster with port mapping, use localhost:8080
    echo "localhost:8080"
}

# Function to setup port forward (backup method if direct access doesn't work)
setup_port_forward() {
    echo -e "${BLUE}Setting up port forward to Gateway...${NC}"
    # Kill any existing port-forward on 8080
    pkill -f "port-forward.*envoy-gateway" 2>/dev/null || true
    sleep 2
    
    # Get the gateway service
    GATEWAY_SERVICE=$(kubectl get svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=eg -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$GATEWAY_SERVICE" ]; then
        echo -e "${YELLOW}Starting port-forward in background...${NC}"
        kubectl port-forward -n envoy-gateway-system svc/${GATEWAY_SERVICE} 8080:80 > /dev/null 2>&1 &
        sleep 3
        echo -e "${GREEN}✓ Port-forward active on localhost:8080${NC}"
    fi
}

# Function to test endpoint
test_endpoint() {
    local host=$1
    local path=${2:-/}
    local address=$(get_gateway_address)
    
    echo -e "${BLUE}Testing: curl -H \"Host: ${host}\" http://${address}${path}${NC}"
    echo ""
    curl -s -H "Host: ${host}" "http://${address}${path}" | jq . || curl -s -H "Host: ${host}" "http://${address}${path}"
    echo ""
}

# Function to run basic routing demo
demo_basic() {
    echo -e "${GREEN}========================================="
    echo "Demo 1: Basic HTTP Routing"
    echo "=========================================${NC}"
    
    echo -e "${BLUE}Deploying resources...${NC}"
    kubectl apply -f 01-basic-routing/
    
    wait_for_pods default
    sleep 5
    
    # Setup port forward
    setup_port_forward
    
    echo -e "${GREEN}✓ Deployment complete${NC}"
    echo ""
    echo -e "${YELLOW}Testing the route...${NC}"
    test_endpoint "www.example.com" "/"
    
    echo ""
    echo -e "${YELLOW}Resources deployed:${NC}"
    kubectl get gateway,httproute,pods,svc
}

# Function to run URL rewrite demo
demo_rewrite() {
    echo -e "${GREEN}========================================="
    echo "Demo 2: URL Rewriting"
    echo "=========================================${NC}"
    
    # Ensure basic setup is deployed
    kubectl apply -f 01-basic-routing/gateway.yaml
    kubectl apply -f 01-basic-routing/gateway_class.yaml
    kubectl apply -f 01-basic-routing/svc_account.yaml
    kubectl apply -f 01-basic-routing/product-service-deploy.yaml
    kubectl apply -f 01-basic-routing/product-service-svc.yaml
    
    wait_for_pods default
    
    echo -e "${BLUE}Deploying URL rewrite route...${NC}"
    kubectl apply -f 02-url-rewrite/
    
    sleep 3
    setup_port_forward
    
    echo -e "${GREEN}✓ Deployment complete${NC}"
    echo ""
    echo -e "${YELLOW}Testing URL rewrite...${NC}"
    echo "Request to /get will be rewritten to /replace"
    test_endpoint "path.rewrite.example" "/get"
    
    echo ""
    echo -e "${YELLOW}HTTPRoute:${NC}"
    kubectl get httproute http-filter-url-rewrite -o yaml | grep -A 10 "filters:"
}

# Function to run traffic splitting demo
demo_splitting() {
    echo -e "${GREEN}========================================="
    echo "Demo 3: Traffic Splitting (Round Robin)"
    echo "=========================================${NC}"
    
    # Ensure basic setup is deployed
    kubectl apply -f 01-basic-routing/gateway.yaml
    kubectl apply -f 01-basic-routing/gateway_class.yaml
    kubectl apply -f 01-basic-routing/svc_account.yaml
    kubectl apply -f 01-basic-routing/product-service-deploy.yaml
    kubectl apply -f 01-basic-routing/product-service-svc.yaml
    
    echo -e "${BLUE}Deploying second backend and traffic splitting route...${NC}"
    kubectl apply -f 03-traffic-splitting/
    
    wait_for_pods default
    sleep 5
    setup_port_forward
    
    echo -e "${GREEN}✓ Deployment complete${NC}"
    echo ""
    echo -e "${YELLOW}Testing traffic splitting (making 10 requests)...${NC}"
    echo "Watch the 'pod' field to see requests distributed:"
    echo ""
    
    for i in {1..10}; do
        echo -e "${BLUE}Request $i:${NC}"
        curl -s -H "Host: backends.example" "http://$(get_gateway_address)/" | jq -r '.pod' 2>/dev/null || \
        curl -s -H "Host: backends.example" "http://$(get_gateway_address)/" | grep -o 'pod"[^"]*' || echo "Response received"
    done
    
    echo ""
    echo -e "${YELLOW}Services:${NC}"
    kubectl get svc | grep -E "NAME|product-service|user-service"
}

# Function to run weighted routing demo
demo_weighted() {
    echo -e "${GREEN}========================================="
    echo "Demo 4: Weighted Traffic Distribution"
    echo "=========================================${NC}"
    
    # Ensure basic setup is deployed
    kubectl apply -f 01-basic-routing/gateway.yaml
    kubectl apply -f 01-basic-routing/gateway_class.yaml
    kubectl apply -f 01-basic-routing/svc_account.yaml
    kubectl apply -f 01-basic-routing/product-service-deploy.yaml
    kubectl apply -f 01-basic-routing/product-service-svc.yaml
    kubectl apply -f 03-traffic-splitting/user-service/
    
    wait_for_pods default
    
    echo -e "${BLUE}Deploying weighted routing (80/20 split)...${NC}"
    kubectl apply -f 04-weighted-routing/
    
    sleep 5
    setup_port_forward
    
    echo -e "${GREEN}✓ Deployment complete${NC}"
    echo ""
    echo -e "${YELLOW}Testing weighted distribution (80% product-service, 20% user-service)...${NC}"
    echo "Making 20 requests to see the distribution:"
    echo ""
    
    declare -A pod_count
    
    for i in {1..20}; do
        RESPONSE=$(curl -s -H "Host: backends.example" "http://$(get_gateway_address)/")
        POD=$(echo $RESPONSE | jq -r '.pod' 2>/dev/null || echo $RESPONSE | grep -o 'product-service\|user-service' | head -1)
        pod_count[$POD]=$((${pod_count[$POD]:-0} + 1))
        echo -n "."
    done
    
    echo ""
    echo ""
    echo -e "${GREEN}Traffic Distribution:${NC}"
    for pod in "${!pod_count[@]}"; do
        percentage=$((${pod_count[$pod]} * 100 / 20))
        echo "  $pod: ${pod_count[$pod]}/20 requests ($percentage%)"
    done
    
    echo ""
    echo -e "${YELLOW}HTTPRoute weights:${NC}"
    kubectl get httproute http-headers -o jsonpath='{.spec.rules[0].backendRefs[*].weight}' | xargs -n1 echo "Weight:"
}

# Function to cleanup
cleanup() {
    echo -e "${YELLOW}Cleaning up all resources...${NC}"
    kubectl delete httproute --all
    kubectl delete gateway --all
    kubectl delete deployment --all
    kubectl delete svc --all
    kubectl delete sa --all
    pkill -f "port-forward.*envoy-gateway" 2>/dev/null || true
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Main script logic
case "$DEMO_TYPE" in
    basic)
        demo_basic
        ;;
    rewrite)
        demo_rewrite
        ;;
    splitting)
        demo_splitting
        ;;
    weighted)
        demo_weighted
        ;;
    all)
        demo_basic
        echo ""
        read -p "Press Enter to continue to URL Rewrite demo..."
        cleanup
        demo_rewrite
        echo ""
        read -p "Press Enter to continue to Traffic Splitting demo..."
        cleanup
        demo_splitting
        echo ""
        read -p "Press Enter to continue to Weighted Routing demo..."
        cleanup
        demo_weighted
        ;;
    cleanup)
        cleanup
        ;;
    *)
        echo -e "${RED}Usage: $0 {basic|rewrite|splitting|weighted|all|cleanup}${NC}"
        echo ""
        echo "Available demos:"
        echo "  basic     - Basic HTTP routing with GatewayClass, Gateway, and HTTPRoute"
        echo "  rewrite   - URL path rewriting demonstration"
        echo "  splitting - Equal traffic distribution between two services"
        echo "  weighted  - Weighted traffic distribution (80/20 split)"
        echo "  all       - Run all demos in sequence"
        echo "  cleanup   - Remove all demo resources"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Demo complete!${NC}"
