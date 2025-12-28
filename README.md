# Kubernetes Gateway API Demo 🚀

A comprehensive demonstration of Kubernetes Gateway API features using **kind** (Kubernetes in Docker) cluster and **Envoy Gateway** controller. This repository showcases real-world routing patterns including basic HTTP routing, URL rewriting, traffic splitting, and weighted load balancing.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Demos](#demos)
- [Architecture](#architecture)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Learning Resources](#learning-resources)

## 🎯 Overview

The **Kubernetes Gateway API** is the next-generation routing API for Kubernetes, designed to improve upon the Ingress API. It provides:

- **Role-oriented design**: Separates concerns between cluster operators and application developers
- **Portable**: Works across different implementations (Envoy, Istio, Nginx, etc.)
- **Expressive**: Supports advanced routing features like traffic splitting, header-based routing, and more
- **Extensible**: Allows custom routing policies and filters

This demo uses:
- **kind**: Local Kubernetes cluster running in Docker
- **Envoy Gateway**: Implementation of the Gateway API
- **Port forwarding**: Access Gateway services from localhost:8080

## 📦 Prerequisites

Before running these demos, ensure you have the following installed:

- **Docker Desktop** (or Docker Engine)
  ```bash
  docker --version  # Should be 20.10+
  ```

- **kubectl** - Kubernetes CLI
  ```bash
  kubectl version --client  # Should be 1.25+
  ```

- **kind** - Kubernetes in Docker (auto-installed by setup.sh on macOS)
  ```bash
  kind version  # Should be 0.17+
  ```

- **helm** - Kubernetes package manager (auto-installed by setup.sh on macOS)
  ```bash
  helm version  # Should be 3.10+
  ```

- **curl** - For testing HTTP endpoints
  ```bash
  curl --version
  ```

- **jq** - JSON processor for parsing responses (optional but recommended)
  ```bash
  brew install jq  # macOS
  ```

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Navigate to the project directory
cd kubernetes-gateway-api

# Make scripts executable
chmod +x setup.sh run-demo.sh cleanup.sh

# Run the automated setup
./setup.sh
```

The setup script will:
1. ✅ Check for required tools (kind, kubectl, helm)
2. ✅ Create a kind cluster with port mappings (80→8080, 443→8443)
3. ✅ Install Envoy Gateway using Helm
4. ✅ Wait for all components to be ready

### 2. Run Demos

Run individual demos:

```bash
# Demo 1: Basic HTTP Routing
./run-demo.sh basic

# Demo 2: URL Rewriting
./run-demo.sh rewrite

# Demo 3: Traffic Splitting (Equal Distribution)
./run-demo.sh splitting

# Demo 4: Weighted Routing (80/20 split)
./run-demo.sh weighted
```

Or run all demos in sequence:

```bash
./run-demo.sh all
```

### 3. Manual Testing

After deploying any demo, you can test manually:

```bash
# Basic routing test
curl -H "Host: www.example.com" http://localhost:8080/

# URL rewrite test
curl -H "Host: path.rewrite.example" http://localhost:8080/get

# Traffic splitting test (run multiple times to see distribution)
for i in {1..10}; do
  curl -s -H "Host: backends.example" http://localhost:8080/ | jq -r '.pod'
done
```

## 📁 Project Structure

```
kubernetes-gateway-api/
│
├── README.md                          # This file - main documentation
├── kind-config.yaml                   # Kind cluster configuration with port mappings
├── setup.sh                           # Automated cluster setup script
├── run-demo.sh                        # Demo runner script
├── cleanup.sh                         # Complete cleanup script
│
├── 00-install/                        # Gateway installation resources
│   └── README.md                      # Installation instructions
│
├── 01-basic-routing/                  # Demo 1: Basic HTTP routing
│   ├── README.md                      # Basic routing documentation
│   ├── gateway_class.yaml             # Defines the Gateway class (eg)
│   ├── gateway.yaml                   # Creates Gateway instance
│   ├── svc_account.yaml               # ServiceAccount for pod identity
│   ├── product-service-deploy.yaml    # Product service deployment
│   ├── product-service-svc.yaml       # Product service
│   └── product-service-route.yaml     # HTTPRoute for product service
│
├── 02-url-rewrite/                    # Demo 2: URL path rewriting
│   ├── README.md                      # URL rewrite documentation
│   └── rewrite-httproute.yaml         # HTTPRoute with URL rewrite filter
│
├── 03-traffic-splitting/              # Demo 3: Equal traffic distribution
│   ├── README.md                      # Traffic splitting documentation
│   ├── httproute_traffic_splitting.yaml   # Route splitting traffic equally
│   └── user-service/                  # Second service for splitting
│       ├── user-service-deploy.yaml   # User service deployment
│       ├── user-service-svc.yaml      # User service
│       └── user-service-sa.yaml       # User service account
│
└── 04-weighted-routing/               # Demo 4: Weighted load balancing
    ├── README.md                      # Weighted routing documentation
    └── httproute_weighted.yaml        # Route with 80/20 weight distribution
```

## 🎓 Demos

### Demo 1: Basic HTTP Routing
**Location**: `01-basic-routing/`

Demonstrates the fundamental components of Gateway API:
- **GatewayClass**: Defines which controller (Envoy) manages Gateways
- **Gateway**: Configures a load balancer listening on port 80
- **HTTPRoute**: Routes traffic from `www.example.com` to product-service
- **Service & Deployment**: Backend application (echo server)

**Use Case**: Standard HTTP routing - the foundation for all other demos

[📖 Detailed Documentation](01-basic-routing/README.md)

### Demo 2: URL Rewriting
**Location**: `02-url-rewrite/`

Shows how to rewrite URLs before they reach the backend:
- Incoming request: `GET /get`
- Rewritten to: `GET /replace`
- Backend receives the modified path

**Use Case**: API versioning, path normalization, legacy system integration

[📖 Detailed Documentation](02-url-rewrite/README.md)

### Demo 3: Traffic Splitting
**Location**: `03-traffic-splitting/`

Demonstrates equal distribution of traffic across multiple services:
- 50% traffic → product-service
- 50% traffic → user-service
- Round-robin load balancing

**Use Case**: A/B testing, multi-service architectures, gradual rollouts

[📖 Detailed Documentation](03-traffic-splitting/README.md)

### Demo 4: Weighted Routing
**Location**: `04-weighted-routing/`

Shows proportional traffic distribution:
- 80% traffic → product-service (stable version)
- 20% traffic → user-service (canary version)

**Use Case**: Canary deployments, blue-green deployments, gradual feature rollouts

[📖 Detailed Documentation](04-weighted-routing/README.md)

## 🏗️ Architecture

### Gateway API Concepts

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Requests                          │
│                  (curl, browser, etc.)                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   GatewayClass                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Controller: gateway.envoyproxy.io                   │   │
│  │  (Defines which implementation handles Gateways)     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      Gateway (eg)                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Listeners:                                          │   │
│  │    - Port 80 (HTTP)                                  │   │
│  │    - Port 443 (HTTPS - future)                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────┬───────────────────────────────────┘
                          │
                ┌─────────┴─────────┐
                ▼                   ▼
    ┌───────────────────┐   ┌──────────────────┐
    │   HTTPRoute 1     │   │   HTTPRoute 2    │
    │  (www.example)    │   │  (backends.ex)   │
    └────────┬──────────┘   └────────┬─────────┘
             │                       │
             ▼                       ▼
    ┌────────────────┐      ┌────────────────┐
    │ product-service│      │  user-service  │
    │   (Pods)       │      │    (Pods)      │
    └────────────────┘      └────────────────┘
```

### Components Hierarchy

1. **GatewayClass** (Cluster-scoped)
   - Managed by: Cluster Operator
   - Defines: Which controller implementation to use

2. **Gateway** (Namespace-scoped)
   - Managed by: Cluster Operator
   - Defines: Load balancer configuration, listeners

3. **HTTPRoute** (Namespace-scoped)
   - Managed by: Application Developer
   - Defines: Traffic routing rules, filters, backend services

4. **Services** (Namespace-scoped)
   - Managed by: Application Developer
   - Defines: Backend application endpoints

## 🧹 Cleanup

### Clean up specific demo resources

```bash
kubectl delete httproute --all
kubectl delete deployment --all
kubectl delete svc --all
```

### Complete cleanup (delete everything including cluster)

```bash
./cleanup.sh
```

This will:
1. Delete all Kubernetes resources
2. Stop any port-forwards
3. Delete the kind cluster

## 🔧 Troubleshooting

### Port 8080 already in use

```bash
# Find and kill the process using port 8080
lsof -ti:8080 | xargs kill -9

# Or use a different port in kind-config.yaml
```

### Gateway not accessible

```bash
# Check Gateway status
kubectl get gateway eg -o yaml

# Check if Envoy pods are running
kubectl get pods -n envoy-gateway-system

# Check Gateway service
kubectl get svc -n envoy-gateway-system
```

### Pods not starting

```bash
# Check pod status
kubectl get pods

# View pod logs
kubectl logs <pod-name>

# Describe pod for events
kubectl describe pod <pod-name>
```

### HTTPRoute not working

```bash
# Check HTTPRoute status
kubectl get httproute

# Describe HTTPRoute for detailed info
kubectl describe httproute <route-name>

# Verify parentRef matches Gateway name
kubectl get httproute <route-name> -o yaml | grep -A 5 parentRefs
```

### Port-forward not working

The demo uses kind cluster with port mappings, so port-forward shouldn't be necessary. However, if you need it:

```bash
# Manual port-forward to Gateway service
GATEWAY_SERVICE=$(kubectl get svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=eg -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n envoy-gateway-system svc/${GATEWAY_SERVICE} 8080:80
```

## 📚 Learning Resources

### Official Documentation
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
- [Envoy Gateway Documentation](https://gateway.envoyproxy.io/)
- [Kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)

### Key Concepts
- [Gateway API Concepts](https://gateway-api.sigs.k8s.io/concepts/api-overview/)
- [HTTPRoute Specification](https://gateway-api.sigs.k8s.io/api-types/httproute/)
- [Traffic Splitting](https://gateway-api.sigs.k8s.io/guides/traffic-splitting/)

### Advanced Topics
- [TLS Configuration](https://gateway-api.sigs.k8s.io/guides/tls/)
- [Request Redirect](https://gateway-api.sigs.k8s.io/guides/http-redirect-rewrite/)
- [Header Manipulation](https://gateway-api.sigs.k8s.io/guides/http-header-modifier/)

## 🤝 Contributing

Feel free to submit issues or pull requests to improve these demos!

## 📄 License

This project is for educational purposes.

---

**Happy Learning! 🎉**

For questions or issues, please check the [Troubleshooting](#troubleshooting) section or consult the official Gateway API documentation.
