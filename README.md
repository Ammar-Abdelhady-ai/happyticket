# HappyTicket - Production Kubernetes Infrastructure

This is my implementation of a real-world ticketing platform running on Kubernetes. I built this from scratch to handle the challenges of deploying a multi-tier .NET application in production - zero downtime during updates, proper monitoring, and automated deployments were my main goals.

## Why This Project?

I wanted to go beyond simple "hello world" Kubernetes deployments. Real applications need more than just running containers - they need proper storage, reliable updates without breaking things, actual monitoring when stuff goes wrong, and automation so you're not manually deploying at 2 AM.

This project reflects what I learned deploying and managing a ticketing application in production, including some hard lessons about database persistence, load balancing, and keeping services available during updates.

## What's Inside

**The Application Stack:**
- .NET 8 API backend handling business logic
- Blazor WebAssembly UI for the frontend
- SQL Server for the database (StatefulSet because data matters)
- MinIO for storing uploaded files and images
- NGINX Ingress for routing traffic and SSL termination

**The Production Stuff:**
- Zero-downtime deployments (because taking the site down for every update isn't acceptable)
- Autoscaling when traffic spikes
- Prometheus + Grafana for actually knowing what's happening
- Centralized logging with EFK stack
- Automated backups (learned this one the hard way)
- CI/CD pipeline that builds, tests, and deploys automatically

## 📋 Table of Contents

- [Project Structure](#-project-structure)
- [Infrastructure Components](#-infrastructure-components)
- [Deployment Strategy](#-deployment-strategy)
- [Zero-Downtime Updates](#-zero-downtime-updates)
- [Installation Guide](#-installation-guide)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Autoscaling](#-autoscaling)
- [Monitoring & Backup](#-monitoring--backup)
- [Configuration](#-configuration)

## 📁 How It's Organized

```
happyticket_k8s/
├── K8S/                          # Kubernetes manifests
│   ├── api/                      # API deployment, services, configs
│   ├── ui/                       # UI deployment, services
│   ├── db/                       # SQL Server StatefulSet, backups
│   ├── minio/                    # MinIO object storage
│   ├── LoadBalancer/             # Ingress NGINX, MetalLB configs
│   ├── dataprotection/           # Persistent volume claims
│   └── namespace/                # Namespace definitions
├── deployment/                   # Ansible automation
│   └── ansible-project/          # Cluster provisioning playbooks
├── sever_files/                  # Server setup scripts
│   ├── fit_data/                 # NFS setup (master/worker nodes)
│   └── fit_storage/              # NFS cluster configuration
├── .github/workflows/            # CI/CD pipelines
└── dockerfiles/                  # Container build files
```

## 🔧 Infrastructure Components

### 1. **Kubernetes Cluster Setup**

The cluster is provisioned using **kubeadm** with the following architecture:

- **Control Plane**: 1 master node managing cluster state
- **Worker Nodes**: 2+ nodes for workload distribution
- **Container Runtime**: containerd
- **Network Plugin**: Calico for pod networking
- **Storage**: NFS for shared persistent volumes

#### Initial Cluster Installation

```bash
# On master node
sudo ./sever_files/fit_data/master_node.sh

# On worker nodes  
sudo ./sever_files/fit_data/worker_node.sh
```

**Automated with Ansible**:
```bash
cd deployment/ansible-project
ansible-playbook -i inventory.INI main.yml
```

### 2. **Load Balancing**

**Ingress NGINX** provides L7 load balancing with:
- SSL/TLS termination via cert-manager
- Path-based routing
- Session affinity (sticky sessions)
- Rate limiting

**MetalLB** (Layer 2 mode) assigns external IPs to LoadBalancer services.

Configuration: `K8S/LoadBalancer/`

### 3. **High Availability**

**Pod Anti-Affinity** ensures replicas run on different nodes:

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - topologyKey: kubernetes.io/hostname
```

**Topology Spread Constraints** evenly distribute pods across nodes.

### 4. **Persistent Storage**

**Dynamic Provisioning** with standard storage class:
- Database: StatefulSet with persistent volumes
- File storage: NFS shares for wwwroot directories
- Backups: Automated SQL Server backups to NFS

## 🚀 Deployment Strategy

### Zero-Downtime Rolling Updates

The deployment uses **RollingUpdate** strategy to ensure zero downtime:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 50%        # Allow 50% more pods during rollout
    maxUnavailable: 50%  # At most 50% can be unavailable
```

**How it works**:
1. New pods are created (maxSurge)
2. Health checks ensure new pods are ready
3. Old pods are terminated (maxUnavailable)
4. Process repeats until all pods are updated

### Readiness & Liveness Probes

Ensures traffic only reaches healthy pods:

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 10
  periodSeconds: 5
```

### Deployment Workflow

```bash
# Apply changes
kubectl apply -f K8S/api/deployment.yml

# Monitor rollout
kubectl rollout status deployment/api -n happyticket

# Rollback if needed
kubectl rollout undo deployment/api -n happyticket
```

## 📦 Installation Guide

### Prerequisites

- Ubuntu 20.04+ servers
- Root/sudo access
- 2+ CPU cores per node
- 4GB+ RAM per node
- Network connectivity between nodes

### Step 1: Configure Variables

Edit configuration files with your environment values:

**Server Setup Scripts**:
```bash
# sever_files/fit_data/worker_node.sh
NFS_SERVER_IP="YOUR_NFS_SERVER_IP"

# sever_files/fit_data/master_node.sh  
CLUSTER_SUBNET="YOUR_CLUSTER_SUBNET"
```

**Ansible Inventory**:
```ini
# deployment/ansible-project/inventory.INI
[cluster]
YOUR_CLUSTER_NODE_IP
```

### Step 2: Bootstrap Cluster with Kubeadm

**On all nodes**:
```bash
# Install container runtime
sudo apt update
sudo apt install -y containerd

# Install kubeadm, kubelet, kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

**On master node**:
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico network plugin
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

**On worker nodes**:
```bash
# Use the join command from kubeadm init output
sudo kubeadm join MASTER_IP:6443 --token TOKEN --discovery-token-ca-cert-hash HASH
```

### Step 3: Configure Secrets

Update secret values in:
- `K8S/api/api-secret.yml`
- `K8S/ui/secret.yml`
- `K8S/db/secret.yml`
- `K8S/minio/secret.yml`

Replace all `CHANGE_ME_*` placeholders with actual values.

### Step 4: Deploy Application

```bash
# Create namespace
kubectl apply -f K8S/namespace/

# Deploy database
kubectl apply -f K8S/db/

# Deploy MinIO
kubectl apply -f K8S/minio/

# Deploy API
kubectl apply -f K8S/api/

# Deploy UI
kubectl apply -f K8S/ui/

# Configure Ingress
kubectl apply -f K8S/LoadBalancer/
```

### Step 5: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n happyticket

# Check services
kubectl get svc -n happyticket

# Check ingress
kubectl get ingress -n happyticket
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

Located in `.github/workflows/deploy.yml`, the pipeline implements:

1. **Build Phase**:
   - Checkout code
   - Setup .NET 8.0
   - Install WebAssembly tools
   - Publish API & Blazor (Linux-x64)
   - Exclude wwwroot from build (preserves user uploads)

2. **Package Phase**:
   - Zip published applications
   - Encode to base64 for transfer
   - Upload via SCP to server

3. **Deploy Phase** (Zero-Downtime):
   - Extract to standby directory
   - Copy existing wwwroot (preserve user data)
   - Atomic swap: archive old → deploy new
   - Restart systemd services
   - Nginx reload for new configuration

**Deployment Strategy**: Blue-Green style with standby directory ensures instant rollback capability.

### Automated Database Backups

CronJob runs daily at 2 AM:

```yaml
schedule: "0 2 * * *"
```

Features:
- Full database backups to NFS
- 7-day retention policy
- Automatic cleanup of old backups

Configuration: `K8S/db/backups/mssql-backup.yml`

## 📈 Autoscaling

### Horizontal Pod Autoscaler (HPA)

**API Autoscaling**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**UI Autoscaling**:
- Min replicas: 2
- Max replicas: 8
- Target: 70% CPU utilization

### Cluster Autoscaler

For cloud deployments (GKE/EKS/AKS), configure cluster autoscaler to add/remove nodes based on pending pods.

## 📊 Monitoring & Logging

### Monitoring Stack (Prometheus + Grafana)

Deploy the complete monitoring stack:

```bash
kubectl apply -f K8S/Grafana/
```

#### Prometheus Metrics Collection

**Metrics Collected**:
- **Pod Resources**: CPU/Memory usage, restarts, status
- **Application Metrics**: 
  - HTTP request rates and latency
  - API endpoint response times
  - Error rates (4xx, 5xx)
- **Database Metrics**:
  - Connection pool usage
  - Query execution time
  - Transaction rates
- **Ingress Metrics**:
  - Traffic volume
  - SSL certificate expiration
  - Backend health status

**ServiceMonitor Configuration**:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: api-metrics
  namespace: happyticket
spec:
  selector:
    matchLabels:
      app: api
  endpoints:
  - port: metrics
    interval: 30s
```

#### Grafana Dashboards

Access Grafana:
```bash
kubectl port-forward svc/grafana 3000:3000 -n monitoring
```

**Pre-configured Dashboards**:
1. **Kubernetes Cluster Overview**: Node health, resource usage
2. **Application Performance**: Request rates, latency, errors
3. **Database Monitoring**: SQL Server performance metrics
4. **Ingress Analytics**: Traffic patterns, top endpoints

#### Alerting Rules

**Critical Alerts**:
- Pod crash loop detected
- High memory/CPU usage (>80%)
- Database connection failures
- API error rate spike (>5%)
- Certificate expiring within 7 days

**Alert Routing**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
data:
  alertmanager.yml: |
    receivers:
    - name: 'team-email'
      email_configs:
      - to: 'ops@happyticket.com'
        from: 'alerts@happyticket.com'
```

### Centralized Logging (EFK Stack)

**Elasticsearch** for log storage, **Fluentd** for log collection, **Kibana** for visualization.

#### Fluentd DaemonSet

Deploys on every node to collect container logs:

```bash
kubectl apply -f https://raw.githubusercontent.com/fluent/fluentd-kubernetes-daemonset/master/fluentd-daemonset-elasticsearch.yaml
```

**Log Collection**:
- Application logs (stdout/stderr)
- System logs (kubelet, containerd)
- Audit logs (API server)
- Ingress access logs

#### Elasticsearch Deployment

**Storage Requirements**:
- Persistent volume: 100GB+
- Retention: 30 days (configurable)

```yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: happyticket-logs
spec:
  version: 8.8.0
  nodeSets:
  - name: default
    count: 3
    config:
      node.store.allow_mmap: false
```

#### Kibana Query Examples

**Access Kibana**:
```bash
kubectl port-forward svc/kibana 5601:5601 -n logging
```

**Useful Queries**:
```
# API errors in last hour
kubernetes.namespace:"happyticket" AND kubernetes.labels.app:"api" AND level:"error"

# Slow database queries
kubernetes.labels.app:"db" AND message:"execution time" AND duration:>1000

# Failed authentication attempts
message:"authentication failed" OR message:"401 Unauthorized"

# Pod restarts
message:"container restarted" AND kubernetes.namespace:"happyticket"
```

#### Log Retention Policy

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: elasticsearch-curator
spec:
  schedule: "0 3 * * *"  # Daily at 3 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: curator
            image: untergeek/curator:latest
            args:
            - --config
            - /etc/curator/curator.yml
            - /etc/curator/actions.yml
```

**Retention Rules**:
- Application logs: 30 days
- System logs: 60 days
- Audit logs: 90 days (compliance requirement)

### Log Aggregation Best Practices

**Structured Logging** (JSON format):
```json
{
  "timestamp": "2026-01-08T18:21:00Z",
  "level": "ERROR",
  "service": "api",
  "message": "Database connection timeout",
  "userId": "12345",
  "endpoint": "/api/tickets",
  "duration_ms": 5000,
  "trace_id": "abc-123-xyz"
}
```

**Log Levels**:
- `DEBUG`: Detailed diagnostic information
- `INFO`: General informational messages
- `WARN`: Warning messages, potential issues
- `ERROR`: Error events, application still running
- `FATAL`: Critical failures, application stopped

### Distributed Tracing (Optional)

For advanced debugging, integrate **Jaeger** or **Zipkin**:

```bash
kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/main/all-in-one/jaeger-all-in-one-template.yml
```

**Benefits**:
- Track requests across microservices
- Identify bottlenecks
- Visualize call chains
- Performance optimization

### Database Backups

**Automated Backups**:
- Full backup: Daily at 2 AM
- Retention: 7 days
- Location: NFS `/backups`

**Manual Backup**:
```bash
kubectl create job --from=cronjob/mssql-backup manual-backup-$(date +%Y%m%d) -n happyticket
```

**Restore**:
```bash
# Copy backup to pod
kubectl cp backup.bak db-0:/var/opt/mssql/data/ -n happyticket

# Execute restore
kubectl exec -it db-0 -n happyticket -- /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
  -Q "RESTORE DATABASE NewHappy2 FROM DISK='/var/opt/mssql/data/backup.bak' WITH REPLACE"
```

## ⚙️ Configuration

### Environment Variables

Managed via ConfigMaps and Secrets:

**ConfigMaps** (`K8S/api/configmap.yml`):
- Non-sensitive configuration
- Feature flags
- API endpoints

**Secrets** (`K8S/api/api-secret.yml`):
- Database passwords
- JWT keys
- Email credentials
- API keys

### Image Management

Update image tags in deployments:

```yaml
containers:
  - name: api
    image: YOUR_REGISTRY/happyticket-api:v1.2.3
```

Use placeholders for generic deployment:
```yaml
image: CHANGE_ME_IMAGE_NAME
```

## 🛠️ Troubleshooting

### Common Issues

**Pods not starting**:
```bash
kubectl describe pod POD_NAME -n happyticket
kubectl logs POD_NAME -n happyticket
```

**Service not accessible**:
```bash
kubectl get endpoints -n happyticket
kubectl get svc -n happyticket
```

**Persistent volume issues**:
```bash
kubectl get pv,pvc -n happyticket
kubectl describe pvc PVC_NAME -n happyticket
```

### Health Checks

```bash
# Check cluster health
kubectl get nodes
kubectl get componentstatuses

# Check all resources
kubectl get all -n happyticket

# Check events
kubectl get events -n happyticket --sort-by='.lastTimestamp'
```

## 📝 License

This is a portfolio/demonstration project showcasing Kubernetes infrastructure skills.

## 🤝 Contributing

This repository serves as a reference implementation. Feel free to fork and adapt for your own projects.

## 📧 Contact

For questions or collaboration opportunities, please reach out via GitHub.

---

**Built with**: Kubernetes • Docker • Ansible • .NET • SQL Server • MinIO • NGINX
