
# Staff Software Engineer – DevOps / Platform Challenge (1 Hour)

## 🎯 Objective

This exercise evaluates **Staff-level engineering capability**, not just Kubernetes syntax.

You are expected to demonstrate:

- Deep Kubernetes knowledge
- Strong Helm templating skills
- Production-grade thinking
- Security awareness
- Observability understanding
- Architectural reasoning
- Clear trade-off analysis

This is not about “making it work”.  
It is about showing how you think at scale.

---

# 🧩 Scenario

You are joining a company where multiple teams will use this Helm chart to deploy an internal service.

The current repository contains:

- A Node.js API instrumented with OpenTelemetry
- A PostgreSQL database
- A Helm chart
- A Prometheus instance scraping metrics

⚠ Several configurations are intentionally incorrect or incomplete.

---

# ⏱ Timebox

You have **1 hour**.

Focus on correctness, clarity, and production thinking.

---

# ✅ Minimum Requirements

You must:

1. Deploy the system to Minikube using Helm
2. Ensure:
   - 2 replicas of the API
   - 1 replica of PostgreSQL
3. Ensure the API can communicate with the database and serve requests
4. Ensure proper security practices for sensitive configuration
5. Ensure observability metrics are properly collected

---

# 🧠 Staff-Level Expectations

Beyond fixing issues, you should consider:

## Architecture

- Is PostgreSQL defined correctly for production?
- Would you use Deployment or StatefulSet? Why?
- What is missing for real persistence?

## Security

- Should secrets live in values.yaml?
- How would you manage secrets in production?
- Would you use Vault / External Secrets / Cloud provider secret manager?
- Should containers run as root?

## Reliability

- What happens during rolling updates?
- Are readiness and liveness probes needed?
- What happens if the database restarts?
- How would you handle backups and disaster recovery?

## Scalability

- Should this API use HPA?
- Based on CPU or custom metrics?
- How would you prevent noisy neighbor problems?

## Observability

- Metrics are exposed via OpenTelemetry and scraped by Prometheus.
- How would you extend this to include traces?
- How would you define SLOs?
- Where would alerts live?

## Multi-Team Usage

Assume this Helm chart will be used by 20 internal teams:

- How would you version it?
- How would you prevent breaking changes?
- How would you standardize security policies?
- Would you use a platform engineering approach?

---

# 🛠 Environment Assumptions

You have:

- **Kubernetes local cluster**: Minikube OR Kind (your choice)
- Helm
- Docker
- kubectl

---

# 🚀 Quick Start

## Option 1: Automated Setup (Recommended)

We provide helper scripts to streamline the setup process. The script supports both **Minikube** and **Kind** - you can choose your preferred tool:

```bash
# Make scripts executable
chmod +x start.sh stop.sh

# Start the entire environment
./start.sh
# The script will detect or ask which cluster you want to use (Minikube or Kind)

# When done, cleanup
./stop.sh
```

The `start.sh` script will:
- Verify prerequisites (kubectl, Helm, Docker)
- Detect or let you choose between Minikube or Kind
- Start/create the cluster if needed
- Configure Docker environment
- Build the application image
- Load image to cluster (Kind) or configure Docker env (Minikube)
- Install/upgrade the Helm chart
- Display status and useful commands

## Option 2: Manual Setup

If you prefer manual control, choose one option below:

### Using Minikube

```bash
# Start Minikube
minikube start

# Configure Docker to use Minikube's daemon
eval $(minikube docker-env)

# Build image
docker build -t staff-app:latest ./app

# Install Helm chart
helm install staff ./helm/staff-app

# Verify deployment
kubectl get pods
kubectl get services
```

### Using Kind

```bash
# Create Kind cluster
kind create cluster --name kind

# Build image
docker build -t staff-app:latest ./app

# Load image into Kind
kind load docker-image staff-app:latest --name kind

# Install Helm chart
helm install staff ./helm/staff-app

# Verify deployment
kubectl get pods
kubectl get services
```

---

# 🔎 What Is Intentionally Broken

The system has intentional configuration issues and production readiness gaps that need to be identified and fixed.

---

# 📊 Evaluation Criteria

We will evaluate:

- Depth of Kubernetes knowledge
- Helm templating maturity
- Security awareness
- Observability understanding
- Production mindset
- Communication clarity
- Architectural reasoning

---

Good luck. Think like a Staff Engineer.
