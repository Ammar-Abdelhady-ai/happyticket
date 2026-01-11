# HappyTicket - Enterprise Kubernetes Infrastructure

<div align="center">

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Ansible](https://img.shields.io/badge/ansible-%23EE0000.svg?style=for-the-badge&logo=ansible&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![.NET](https://img.shields.io/badge/.NET-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)
![MicrosoftSQLServer](https://img.shields.io/badge/SqlServer-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)

</div>

## 📖 Introduction

**HappyTicket** is a production-grade ticketing platform running on a custom **On-Premise Kubernetes Cluster**.

Unlike managed cloud solutions (EKS/AKS), this project demonstrates the complexity of building infrastructure from scratch on bare metal. I architected the entire lifecycle—from provisioning servers with **Ansible** to configuring **High Availability** (HA) schedules and **Zero-Downtime** deployments.

## 🏗️ Architecture Overview

The system utilizes a microservices architecture orchestrated by Kubernetes.

| Layer | Technology | Details |
|-------|------------|---------|
| **Infrastructure** | **Bare Metal** | Hosted on custom Linux nodes. |
| **Provisioning** | **Ansible** | Automated cluster bootstrapping and node configuration. |
| **Orchestration** | **Kubernetes** | Self-managed control plane & worker nodes (v1.32). |
| **Networking** | **Calico & NGINX** | CNI for pod networking; Ingress Controller for traffic routing. |
| **Storage** | **NFS & PVCs** | Dynamic storage provisioning for stateful workloads (SQL, MinIO). |
| **CI/CD** | **GitHub Actions** | Automated build and deployment pipelines. |

## 📂 Repository Structure

The repository is organized to reflect standard DevOps practices:

```bash
happyticket
├── ansible/             # IaC playbooks for cluster provisioning & configuration
├── kubernetes/          # K8s Manifests (Deployments, Services, StatefulSets)
│   ├── api/             # .NET API Backend
│   ├── ui/              # Blazor WebAssembly Frontend
│   ├── db/              # SQL Server & Backup CronJobs
│   └── loadbalancer/    # MetalLB & NGINX Ingress configuration
├── docker-compose/      # Local development environment
├── scripts/             # Shell scripts for node initialization and storage setup
└── .github/workflows/   # CI/CD Pipelines
```

## 🚀 Key Achievements

### 🔧 Deep Dive: On-Premise Cluster
I avoided usage of `minikube` or managed services to truly understand Kubernetes internals.
- **Cluster Bootstrapping**: Used `kubeadm` wrapped in Ansible playbooks to provision the control plane and worker nodes.
- **Network Implementation**: Configured **Calico** for pod-to-pod networking and **MetalLB** to provide Layer 2 load balancing for the Ingress Controller.

### 🔄 Zero-Downtime Deployments
Deployment strategies were critical for this production simulation.
- **Rolling Updates**: Configured `maxSurge` and `maxUnavailable` to ensure user traffic is never dropped during application updates.
- **Probes**: Implemented `liveness` and `readiness` probes to prevent routing traffic to unhealthy pods.

### 🤖 Automation (Infrastructure as Code)
Manual operations were eliminated using Ansible.
- **Idempotency**: Playbooks allow for re-running configuration without side effects.
- **Scalability**: New worker nodes can be added to the cluster by simply updating the `inventory.ini` and running the `worker_node.yml` playbook.

## 🛠️ Deployment Guide

### Prerequisites
- 3x Linux Servers (Ubuntu 20.04+)
- Ansibe Control Node
- SSH Access

### 1. Cluster Provisioning
Navigate to the ansible directory and run the main playbook:

```bash
cd ansible/ansible-project
# Updates system, installs dependencies (Docker, Kubeadm), and initializes cluster
ansible-playbook -i inventory.INI main.yml
```

### 2. Application Deployment
Once the cluster is ready, deploy the manifests:

```bash
# Apply Namespaces and Secrets
kubectl apply -f kubernetes/namespace/

# Deploy Persistent Storage & Database
kubectl apply -f kubernetes/db/

# Deploy Services (API & UI)
kubectl apply -f kubernetes/api/
kubectl apply -f kubernetes/ui/

# Configure Ingress
kubectl apply -f kubernetes/loadbalancer/
```

## 👨‍💻 Author

**Ammar Abdelhady**
*DevOps Engineer | .NET Developer*

> *This project serves as a comprehensive portfolio of my skills in Cloud Native Infrastructure, Automation, and Full Stack Development.*
    