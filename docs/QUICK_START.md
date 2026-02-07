# Quick Start

This guide prepares you to deliver an intentionnaly vulnerable Web App.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- kubectl installed
- Terraform installed
- Docker installed (for local testing)
- Git configured

## 5-Minute Quick Deploy

### Step 1: Clone Repository
```bash
git clone https://github.com/neuralhawk7/cnapp-exercise.git
cd cnapp-exercise
```

### Step 2: Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply -auto-approve
# Wait ~20 minutes for deployment
```

### Step 3: Configure kubectl
```bash
aws eks update-kubeconfig --name express-hello-v2 --region us-east-1
kubectl get nodes  # Verify cluster access
```

### Step 4: Deploy Application
```bash
# Create namespace
kubectl create namespace demo

# Apply RBAC (with intentional cluster-admin misconfiguration)
kubectl apply -f ../app/rbac.yaml

# Build and push container (or use existing ECR image)
# See DEPLOYMENT_README.md for detailed steps

# Deploy application
kubectl apply -f ../app/deployment.yaml

# Verify deployment
kubectl get pods -n demo
kubectl get svc -n demo
```

### Step 5: Verify Everything Works
```bash
# Get application URL
kubectl get svc -n demo express-hello

# Test application
curl http://<load-balancer-url>/healthz
curl http://<load-balancer-url>/items
```

## Pre-Flight Checklist (5 minutes)

### 1. Verify Infrastructure
```bash
# Check all resources are running
terraform -chdir=terraform output

# Verify EKS cluster
aws eks describe-cluster --name express-hello-v2

# Verify MongoDB EC2
aws ec2 describe-instances --filters "Name=tag:Name,Values=*mongo*" \
  --query 'Reservations[0].Instances[0].State.Name'
```

### 2. Test Application
```bash
# Get load balancer URL
LB_URL=$(kubectl get svc -n demo express-hello -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://${LB_URL}"

# Test endpoints
curl http://${LB_URL}/healthz  # Should return "ok"
curl http://${LB_URL}/          # Should return API info
curl http://${LB_URL}/items     # Should return JSON array
```

### 3. Open AWS Console Tabs
Open these URLs in your browser:
- Security Hub: https://console.aws.amazon.com/securityhub/
- GuardDuty: https://console.aws.amazon.com/guardduty/
- Inspector: https://console.aws.amazon.com/inspector/v2/
- WAF: https://console.aws.amazon.com/wafv2/
- CloudTrail: https://console.aws.amazon.com/cloudtrail/

### 4. Prepare Terminal
```bash
# Set up convenient aliases
alias k='kubectl'
alias kd='kubectl -n demo'

# Test kubectl
kubectl cluster-info
kubectl get nodes
kd get pods
```

## Demo (15 minutes)

### Part 1: Application (3 minutes)
```bash
# Show application is running
echo "1. Application URL: http://${LB_URL}"
curl http://${LB_URL}

# Show in browser
open http://${LB_URL}  # or xdg-open on Linux

# Test MongoDB connectivity
curl http://${LB_URL}/items
```

### Part 2: Kubernetes (5 minutes)
```bash
# Show cluster
kubectl get nodes
kubectl get ns

# Show deployment
kd get all

# Show RBAC misconfiguration (cluster-admin)
kd get sa
kubectl get clusterrolebinding express-hello-admin -o yaml

# Exec into pod
POD=$(kd get pod -l app=express-hello -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n demo $POD -- sh

# Inside pod:
cat /app/wizexercise.txt
kubectl get secrets --all-namespaces | head -10  # Shows cluster-admin access!
exit
```

### Part 3: Security Services (5 minutes)

**Security Hub:**
1. Open Security Hub dashboard
2. Show compliance score
3. Filter findings by severity: Critical
4. Show specific finding: S3 bucket allows public read

**GuardDuty:**
1. Open GuardDuty findings
2. Show any threat detections
3. Explain finding types

**Inspector:**
1. Open Inspector dashboard
2. Filter by severity: High + Critical
3. Show CVE details for outdated packages

**WAF:**
1. Open WAF dashboard
2. Show configured rules (OWASP Top 10, etc.)
3. Show CloudWatch metrics

### Part 4: CI/CD (2 minutes)
```bash
# Open GitHub repository
echo "https://github.com/neuralhawk7/cnapp-exercise"

# Show workflows
# .github/workflows/infra-ci.yml - Terraform + Checkov
# .github/workflows/app-deploy.yml - Docker + Trivy
# .github/workflows/security-scans.yml - Weekly scans

# Show GitHub Security tab
# Code scanning alerts from Checkov and Trivy
```

## Common Demo Commands

### Kubernetes
```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl get ns

# Demo namespace
kd get all
kd get pods -o wide
kd describe pod <pod-name>
kd logs deployment/express-hello

# RBAC (security issue!)
kd get sa express-hello-sa -o yaml
kubectl get clusterrolebinding express-hello-admin -o yaml

# Exec into pod
POD=$(kd get pod -l app=express-hello -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n demo $POD -- sh
# Inside: cat /app/wizexercise.txt
# Inside: kubectl get secrets --all-namespaces
```

### AWS CLI
```bash
# EC2 MongoDB instance
aws ec2 describe-instances --filters "Name=tag:Name,Values=*mongo*" \
  --query 'Reservations[0].Instances[0].[InstanceId,PublicIpAddress,State.Name]' \
  --output table

# S3 bucket (public access - security issue!)
BUCKET=$(terraform -chdir=terraform output -raw backup_bucket_name)
aws s3 ls s3://${BUCKET}/
curl https://${BUCKET}.s3.amazonaws.com/  # Should work publicly!

# Security Hub
aws securityhub get-findings --max-results 5 \
  --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}'

# GuardDuty
DETECTOR_ID=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)
aws guardduty list-findings --detector-id ${DETECTOR_ID} --max-results 5
```

### MongoDB
```bash
# Get MongoDB IP
MONGO_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*mongo*" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# SSH to MongoDB (shows security issue - public SSH!)
ssh admin@${MONGO_IP}

# On MongoDB VM:
mongod --version           # Should show 4.4.x (outdated!)
lsb_release -a            # Should show Debian 10 (outdated!)
sudo systemctl status mongodb
cat /usr/local/bin/backup-mongodb.sh
sudo crontab -l
```

### Architecture
- "Two-tier architecture with containerized frontend and database backend"
- "Deployed on AWS using managed services: EKS, EC2, VPC"
- "Multi-AZ deployment for high availability"
- "Private subnets for EKS, public subnet for MongoDB (intentional misconfiguration)"

### Security Controls
- "Comprehensive detective controls: GuardDuty, Security Hub, Inspector, CloudTrail, Config"
- "Preventive controls: WAF with OWASP Top 10, security groups, IAM roles"
- "CI/CD security: Checkov for IaC, Trivy for containers, SARIF integration sends results to Security Tab of Repo"

### Misconfigurations
- "Intentionally misconfigured to demonstrate CNAPP value"
- "Critical: Public S3 bucket, cluster-admin pod role"
- "High: SSH exposed, outdated software, permissive IAM"
- "All detected by AWS security services"

### DevOps
- "Infrastructure as Code with Terraform - fully reproducible"
- "CI/CD pipelines with GitHub Actions - automated deployment"
- "Security scanning integrated into every deployment"
- "GitOps approach - all changes tracked and reviewed"

## Troubleshooting

### Application not accessible
```bash
# Check deployment
kd get pods
kd rollout status deployment/express-hello

# Check logs
kd logs deployment/express-hello --tail=50

# Check service
kd get svc
kd describe svc express-hello

# Check MongoDB connectivity from pod
kubectl exec -n demo deployment/express-hello -- nc -zv <mongo-ip> 27017
```

### MongoDB connection failed
```bash
# Verify MongoDB is running
ssh admin@${MONGO_IP} sudo systemctl status mongodb

# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify VPC CIDR is allowed on port 27017
# Should see: 10.0.0.0/16 → 27017
```

### kubectl not working
```bash
# Update kubeconfig
aws eks update-kubeconfig --name express-hello-v2 --region us-east-1

# Verify context
kubectl config current-context

# Test connection
kubectl get nodes
```

## Post-Demo Cleanup

If you need to tear down the environment:

```bash
# Delete Kubernetes resources
kubectl delete namespace demo
kubectl delete ns ingress-nginx

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve
```

## Resources

- **Complete Guide:** [EXERCISE_GUIDE.md](../EXERCISE_GUIDE.md)
- **Presentation:** [docs/PRESENTATION_GUIDE.md](PRESENTATION_GUIDE.md)
- **Validation:** [docs/VALIDATION_CHECKLIST.md](VALIDATION_CHECKLIST.md)
- **Deployment:** [DEPLOYMENT_README.md](../DEPLOYMENT_README.md)

## Tips

1. **Practice the demo** - Run through it at least twice before presenting
2. **Have backups** - Screenshots of security dashboards if demo fails
3. **Know your audience** - Adjust technical depth based on attendees
4. **Be confident** - You built this, you know it well
5. **Show passion** - Demonstrate enthusiasm for security

---

**Ready to present!** 🚀

For questions: See [PRESENTATION_GUIDE.md](PRESENTATION_GUIDE.md) Q&A section
