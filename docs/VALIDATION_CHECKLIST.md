# Wiz Technical Exercise - Validation Checklist

This checklist helps verify that all requirements of the Wiz Technical Exercise are met.

## Pre-Presentation Validation

### Infrastructure Deployment ✅

#### VPC & Networking
- [ ] VPC created with CIDR 10.0.0.0/16
- [ ] Public subnets in 2 AZs
- [ ] Private subnets in 2 AZs
- [ ] Internet Gateway attached
- [ ] NAT Gateway for private subnets
- [ ] Route tables configured correctly

```bash
# Verify VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*express-hello*"

# Verify subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"
```

#### MongoDB EC2 Instance ✅
- [ ] EC2 instance running (t3.medium or similar)
- [ ] Debian 10 (Buster) OS - 1+ year old ✓
- [ ] MongoDB 4.4 installed - 1+ year old ✓
- [ ] SSH port 22 exposed to 0.0.0.0/0 ⚠️
- [ ] MongoDB port 27017 restricted to VPC CIDR ✓
- [ ] Overly permissive IAM role (can create VMs) ⚠️
- [ ] Public IP assigned
- [ ] Security group properly configured

```bash
# Verify instance
aws ec2 describe-instances --filters "Name=tag:Name,Values=*mongo*"

# SSH to instance
ssh admin@<mongodb-public-ip>

# Check OS version
lsb_release -a
# Should show: Debian GNU/Linux 10 (buster)

# Check MongoDB version
mongod --version
# Should show: db version v4.4.x

# Check IAM role permissions
aws iam get-instance-profile --instance-profile-name <profile-name>
aws iam get-role-policy --role-name <role-name> --policy-name <policy-name>
# Should show: ec2:RunInstances, ec2:CreateTags permissions
```

#### S3 Backup Bucket ✅
- [ ] S3 bucket created
- [ ] Public read access enabled ⚠️
- [ ] Public list access enabled ⚠️
- [ ] Backup script configured on MongoDB VM
- [ ] Daily backup cron job configured

```bash
# Verify bucket
aws s3 ls s3://<bucket-name>/

# Test public access
curl https://<bucket-name>.s3.amazonaws.com/
# Should list bucket contents (this is intentionally insecure!)

# Check bucket policy
aws s3api get-bucket-policy --bucket <bucket-name>

# On MongoDB VM, check backup script
ssh admin@<mongodb-ip> cat /usr/local/bin/backup-mongodb.sh
ssh admin@<mongodb-ip> sudo crontab -l
```

#### EKS Cluster ✅
- [ ] EKS cluster created
- [ ] Kubernetes version 1.28 or later
- [ ] Deployed in private subnets
- [ ] Managed node group with 2+ nodes
- [ ] Cluster endpoint access configured
- [ ] IAM roles properly configured

```bash
# Verify cluster
aws eks describe-cluster --name <cluster-name>

# Update kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region us-east-1

# Check nodes
kubectl get nodes

# Verify nodes are in private subnets
kubectl get nodes -o wide
```

### Application Deployment ✅

#### Container Image
- [ ] Dockerfile exists in app/
- [ ] Image built successfully
- [ ] wizexercise.txt file included in image
- [ ] Image pushed to ECR
- [ ] Image tagged appropriately

```bash
# Build image locally to verify
cd app
docker build -t test-image .

# Verify wizexercise.txt in image
docker run --rm test-image cat /app/wizexercise.txt
# Should display your name

# Check ECR
aws ecr describe-images --repository-name cnapp-demo/express-hello
```

#### Kubernetes Deployment
- [ ] Namespace 'demo' exists
- [ ] Deployment created (express-hello)
- [ ] Service account created
- [ ] ClusterRoleBinding with cluster-admin ⚠️
- [ ] Service created (LoadBalancer or ClusterIP)
- [ ] Ingress created
- [ ] NGINX Ingress Controller deployed

```bash
# Check namespace
kubectl get namespace demo

# Check deployment
kubectl get deployment -n demo
kubectl describe deployment express-hello -n demo

# Check service account and RBAC (security issue!)
kubectl get sa -n demo
kubectl get clusterrolebinding express-hello-admin -o yaml
# Should show: roleRef.name: cluster-admin

# Check service
kubectl get svc -n demo

# Check ingress
kubectl get ingress -n demo

# Check NGINX controller
kubectl get svc -n ingress-nginx
```

#### Application Functionality
- [ ] Application accessible via load balancer
- [ ] /healthz endpoint responds
- [ ] / endpoint responds
- [ ] /items endpoint connects to MongoDB
- [ ] MongoDB connectivity working

```bash
# Get load balancer URL
kubectl get ingress -n demo -o wide
# Or
kubectl get svc -n demo

# Test health check
curl http://<alb-dns>/healthz
# Should return: ok

# Test root endpoint
curl http://<alb-dns>/
# Should return: Wiz exercise API running...

# Test MongoDB connection
curl http://<alb-dns>/items
# Should return JSON array (may be empty)
```

### Security Controls ✅

#### Detective Controls
- [ ] GuardDuty enabled
- [ ] Security Hub enabled
- [ ] Security Hub standards enabled (CIS + AWS Foundational)
- [ ] Inspector enabled
- [ ] CloudTrail enabled (multi-region)
- [ ] AWS Config enabled
- [ ] Amazon Detective enabled
- [ ] VPC Flow Logs enabled

```bash
# Check GuardDuty
aws guardduty list-detectors
aws guardduty get-detector --detector-id <detector-id>

# Check Security Hub
aws securityhub describe-hub
aws securityhub get-enabled-standards

# Check Inspector
aws inspector2 list-findings --max-results 10

# Check CloudTrail
aws cloudtrail describe-trails
aws cloudtrail get-trail-status --name <trail-name>

# Check Config
aws configservice describe-configuration-recorders
aws configservice describe-configuration-recorder-status

# Check VPC Flow Logs
aws ec2 describe-flow-logs
```

#### Preventive Controls
- [ ] AWS WAF deployed on ALB
- [ ] WAF rules configured (OWASP Top 10, Known Bad Inputs, SQL, Rate Limit)
- [ ] Security groups properly configured
- [ ] IAM roles follow least privilege (mostly)
- [ ] Network ACLs configured

```bash
# Check WAF
aws wafv2 list-web-acls --scope REGIONAL --region us-east-1

# Check WAF rules
aws wafv2 get-web-acl --scope REGIONAL --id <web-acl-id> --name <web-acl-name> --region us-east-1

# Check security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<vpc-id>"
```

### CI/CD Pipelines ✅

#### Infrastructure Pipeline
- [ ] .github/workflows/infra-ci.yml exists
- [ ] Terraform format check configured
- [ ] Terraform validate configured
- [ ] Checkov IaC scanning configured
- [ ] Yor tagging configured
- [ ] SARIF upload to GitHub Security configured

```bash
# View workflow
cat .github/workflows/infra-ci.yml

# Trigger manually
# Go to GitHub Actions → Infra CI → Run workflow
```

#### Application Pipeline
- [ ] .github/workflows/app-deploy.yml exists
- [ ] Docker build configured
- [ ] Trivy scanning configured
- [ ] ECR push configured
- [ ] Kubernetes deployment update configured
- [ ] OIDC authentication configured

```bash
# View workflow
cat .github/workflows/app-deploy.yml

# Check OIDC provider
aws iam list-open-id-connect-providers
```

#### Security Scanning
- [ ] .github/workflows/security-scans.yml exists
- [ ] Weekly scheduled scans configured
- [ ] Trivy ECR scanning configured
- [ ] SARIF uploads working

```bash
# View workflow
cat .github/workflows/security-scans.yml
```

## Demo Validation

### Kubernetes Demo Commands ✅

```bash
# 1. Cluster info
kubectl cluster-info
kubectl get nodes

# 2. Show all resources in demo namespace
kubectl get all -n demo

# 3. Show RBAC configuration (security issue!)
kubectl get sa express-hello-sa -n demo -o yaml
kubectl get clusterrolebinding express-hello-admin -o yaml

# 4. Exec into pod
POD_NAME=$(kubectl get pod -n demo -l app=express-hello -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n demo $POD_NAME -- sh

# 5. Inside pod - verify wizexercise.txt
cat /app/wizexercise.txt

# 6. Inside pod - demonstrate security risk (cluster-admin access)
kubectl get secrets --all-namespaces | head -20
kubectl get pods --all-namespaces | head -20
# This should work because of cluster-admin role!

# 7. Exit pod
exit
```

### MongoDB Demo Commands ✅

```bash
# 1. SSH to MongoDB instance
ssh admin@<mongodb-public-ip>

# 2. Check MongoDB status
sudo systemctl status mongodb

# 3. Check MongoDB version (should be 4.4.x)
mongod --version

# 4. Check OS version (should be Debian 10)
lsb_release -a
cat /etc/os-release

# 5. Check backup script
cat /usr/local/bin/backup-mongodb.sh

# 6. Check cron job
sudo crontab -l

# 7. List S3 backups
aws s3 ls s3://<backup-bucket>/

# 8. Test public S3 access (security issue!)
exit  # Exit SSH
curl https://<backup-bucket>.s3.amazonaws.com/
# Should list bucket contents publicly!
```

### Security Hub Demo ✅

```bash
# Navigate to AWS Console → Security Hub

# Check these sections:
# 1. Summary dashboard - compliance score
# 2. Standards - AWS Foundational + CIS scores
# 3. Findings - filter by severity
# 4. Insights - top findings
# 5. Integrations - GuardDuty, Inspector, Config

# Look for specific findings:
# - S3 bucket allows public read access
# - EC2 instance has public IP
# - Security group allows 0.0.0.0/0 on port 22
# - Outdated software versions
```

### GuardDuty Demo ✅

```bash
# Navigate to AWS Console → GuardDuty

# Check:
# 1. Findings - any threats detected
# 2. Summary - account statistics
# 3. Settings - enabled features

# Common findings you might see:
# - UnauthorizedAccess:EC2/SSHBruteForce
# - Recon:EC2/PortProbeUnprotectedPort
# - UnauthorizedAccess:IAMUser/MaliciousIPCaller
```

### Inspector Demo ✅

```bash
# Navigate to AWS Console → Inspector

# Check:
# 1. Dashboard - vulnerability summary
# 2. Findings - EC2 and ECR findings
# 3. Filter by severity (Critical, High)

# Look for:
# - Package vulnerabilities in Debian 10
# - CVEs in MongoDB 4.4
# - Container image vulnerabilities
```

### WAF Demo ✅

```bash
# Navigate to AWS Console → WAF

# Check:
# 1. Web ACLs - view configured ACL
# 2. Rules - see OWASP Top 10, SQL injection, etc.
# 3. CloudWatch metrics - request counts
# 4. Sampled requests - see blocked/allowed traffic

# Key metrics:
# - Total requests
# - Blocked requests
# - Rate-based rule triggers
```

## Presentation Checklist

### Before Presentation
- [ ] All infrastructure deployed and healthy
- [ ] Application accessible and working
- [ ] kubectl configured with correct context
- [ ] AWS Console tabs pre-opened:
  - [ ] Security Hub
  - [ ] GuardDuty  
  - [ ] Inspector
  - [ ] WAF
  - [ ] CloudTrail
- [ ] Browser tabs ready:
  - [ ] Application URL
  - [ ] GitHub repository
  - [ ] GitHub Actions
- [ ] Terminal windows ready:
  - [ ] kubectl session
  - [ ] AWS CLI session
  - [ ] SSH session (optional)
- [ ] Slides prepared and tested
- [ ] Demo commands in clipboard/notes
- [ ] Backup screenshots if demo fails

### During Presentation
- [ ] Introduce yourself and agenda (2 min)
- [ ] Explain architecture with diagrams (5 min)
- [ ] Show DevOps implementation (5 min)
- [ ] Demonstrate security controls (10 min)
- [ ] Explain misconfigurations (10 min)
- [ ] Live demo (10 min)
  - [ ] Application functionality
  - [ ] Kubernetes commands
  - [ ] Security Hub
  - [ ] GuardDuty/Inspector
- [ ] Discuss approach and challenges (5 min)
- [ ] Q&A (remaining time)

### After Presentation
- [ ] Answer follow-up questions
- [ ] Provide GitHub repository link
- [ ] Clean up resources if needed

## Troubleshooting

### Application Not Accessible
```bash
# Check deployment status
kubectl get deployment -n demo
kubectl rollout status deployment/express-hello -n demo

# Check pod logs
kubectl logs -n demo deployment/express-hello

# Check service
kubectl get svc -n demo
kubectl describe svc express-hello -n demo

# Check ingress
kubectl get ingress -n demo
kubectl describe ingress express-hello -n demo
```

### MongoDB Connection Issues
```bash
# From EKS pod, test MongoDB connectivity
kubectl exec -it -n demo deployment/express-hello -- sh
nc -zv <mongodb-private-ip> 27017

# Check MongoDB security group
aws ec2 describe-security-groups --group-ids <mongo-sg-id>

# Verify MongoDB is running
ssh admin@<mongodb-ip> sudo systemctl status mongodb
```

### CI/CD Pipeline Failures
```bash
# Check GitHub Actions logs in GitHub UI

# For Terraform issues:
cd terraform
terraform validate
terraform plan

# For Docker build issues:
cd app
docker build -t test .

# For kubectl issues:
kubectl config current-context
kubectl config get-contexts
```

## Success Criteria

You've successfully completed the exercise if you can:

✅ **Demonstrate all components:**
- Working web application
- MongoDB database with connectivity
- All security services enabled
- CI/CD pipelines functioning

✅ **Show intentional misconfigurations:**
- SSH exposed to internet
- Outdated OS and database
- Overly permissive IAM
- Public S3 bucket
- Cluster-admin Kubernetes role

✅ **Prove detection:**
- Security Hub findings
- GuardDuty alerts
- Inspector vulnerabilities
- CloudTrail audit logs

✅ **Execute demo smoothly:**
- kubectl commands work
- Application responds
- Security dashboards accessible
- Can explain architecture

✅ **Answer questions confidently:**
- Architecture decisions
- Security trade-offs
- Production improvements
- Real-world relevance

## Documentation Reference

- [EXERCISE_GUIDE.md](../EXERCISE_GUIDE.md) - Complete implementation guide
- [PRESENTATION_GUIDE.md](PRESENTATION_GUIDE.md) - Slide structure and talking points
- [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md) - System diagrams
- [DEPLOYMENT_README.md](../DEPLOYMENT_README.md) - Deployment instructions
- [WELL_ARCHITECTED.md](../WELL_ARCHITECTED.md) - Architecture justification

---

**Last Updated:** 2024  
**Repository:** github.com/neuralhawk7/cnapp-exercise
