# cnapp-exercise
An intentionally misconfigured project for CNAPP testing

Note: The Debian AMI in this exercise uses the `admin` user for SSH (not `debian`).

## 📚 Documentation

### Getting Started
- [DEPLOYMENT_README.md](DEPLOYMENT_README.md) - How to deploy the infrastructure
- [README.md](README.md) - This file (quick start guide)

### Architecture & Design
- [WELL_ARCHITECTED.md](WELL_ARCHITECTED.md) - AWS Well-Architected Framework alignment
- [docs/ARCHITECTURE_DIAGRAMS.md](docs/ARCHITECTURE_DIAGRAMS.md) - Architecture diagrams

### Exercise Completion
- **[EXERCISE_GUIDE.md](EXERCISE_GUIDE.md)** - **Complete guide demonstrating all Wiz Technical Exercise requirements**
- [docs/PRESENTATION_GUIDE.md](docs/PRESENTATION_GUIDE.md) - 45-minute presentation structure and demo checklist

## 🎯 Wiz Technical Exercise

This repository demonstrates a complete implementation of the Wiz Technical Exercise assignment, featuring:

### Two-Tier Web Application
- ✅ Containerized Node.js Express application on Amazon EKS
- ✅ MongoDB 4.4 database on EC2 (Debian 10)
- ✅ Application exposed via Kubernetes Ingress and AWS ALB
- ✅ MongoDB backups to S3 (intentionally public)

### Intentional Misconfigurations
- ⚠️ SSH exposed to internet (port 22 from 0.0.0.0/0)
- ⚠️ Outdated OS (Debian 10, 1+ year old)
- ⚠️ Outdated MongoDB (version 4.4, 1+ year old)
- ⚠️ Overly permissive IAM role (can create VMs)
- ⚠️ Public S3 bucket (read/list access)
- ⚠️ Cluster-admin Kubernetes role for application pod

### DevOps Implementation
- ✅ Infrastructure as Code with Terraform
- ✅ CI/CD pipelines for infrastructure deployment
- ✅ CI/CD pipelines for container builds and deployments
- ✅ Security scanning (Checkov for IaC, Trivy for containers)
- ✅ GitHub Actions workflows with OIDC authentication

### Security Controls
**Detective Controls:**
- ✅ Amazon GuardDuty (threat detection)
- ✅ AWS Security Hub (CIS + AWS Foundational benchmarks)
- ✅ Amazon Inspector (vulnerability scanning)
- ✅ AWS CloudTrail (multi-region audit logging)
- ✅ AWS Config (configuration tracking)
- ✅ Amazon Detective (security investigation)
- ✅ VPC Flow Logs (network monitoring)

**Preventive Controls:**
- ✅ AWS WAF (OWASP Top 10 protection)
- ✅ Security Groups (network segmentation)
- ✅ IAM Roles (access control)

## 📊 Quick Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      AWS VPC (10.0.0.0/16)                  │
│                                                             │
│  ┌──────────────────┐      ┌────────────────────────────┐  │
│  │  Public Subnet   │      │    Private Subnets         │  │
│  │  ┌────────────┐  │      │  ┌──────────────────────┐  │  │
│  │  │ ALB + WAF  │  │      │  │   EKS Cluster        │  │  │
│  │  └────────────┘  │      │  │  ┌────────────────┐  │  │  │
│  │  ┌────────────┐  │      │  │  │ Express Pods   │  │  │  │
│  │  │ MongoDB EC2│◄─┼──────┼──┼──┤ (cluster-admin)│  │  │  │
│  │  │ (SSH:22)   │  │      │  │  └────────────────┘  │  │  │
│  │  └────────────┘  │      │  └──────────────────────┘  │  │
│  └──────────────────┘      └────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  S3 Bucket (PUBLIC READ) - MongoDB Backups          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

Security Services: GuardDuty, Security Hub, Inspector, 
                  CloudTrail, Config, Detective, VPC Flow Logs
```

## 🚀 Quick Start

1. **Review the complete exercise guide:**
   ```bash
   cat EXERCISE_GUIDE.md
   ```

2. **Deploy infrastructure:**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Deploy application:**
   See [DEPLOYMENT_README.md](DEPLOYMENT_README.md) for detailed steps

4. **Prepare for presentation:**
   See [docs/PRESENTATION_GUIDE.md](docs/PRESENTATION_GUIDE.md)

## 🔍 What to Show in Demo

The exercise includes everything needed for a compelling 45-minute presentation:
- Working web application with MongoDB backend
- Architecture diagrams showing security controls
- Security Hub dashboard with findings
- GuardDuty threat detection
- Inspector vulnerability reports
- CI/CD pipelines with security scanning
- Intentional misconfigurations and their detection
- kubectl demonstrations including cluster-admin access

See [EXERCISE_GUIDE.md](EXERCISE_GUIDE.md) for the complete demo checklist and presentation outline.

## 📈 Repository Structure

```
cnapp-exercise/
├── EXERCISE_GUIDE.md           # Complete exercise implementation guide
├── DEPLOYMENT_README.md         # Deployment instructions
├── WELL_ARCHITECTED.md          # Architecture documentation
├── docs/
│   ├── ARCHITECTURE_DIAGRAMS.md # System diagrams
│   └── PRESENTATION_GUIDE.md    # Presentation structure
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                 # Core resources + security services
│   ├── vpc.tf                  # Network configuration
│   ├── eks.tf                  # Kubernetes cluster
│   └── mongo-vm/               # MongoDB EC2 instance
├── app/                        # Application code
│   ├── server.js               # Express application
│   ├── Dockerfile              # Container image
│   ├── deployment.yaml         # Kubernetes deployment
│   ├── rbac.yaml               # RBAC (cluster-admin)
│   └── wizexercise.txt         # Name file in container
└── .github/workflows/          # CI/CD pipelines
    ├── infra-ci.yml            # Terraform validation + Checkov
    ├── infra-deploy.yml        # Infrastructure deployment
    ├── app-deploy.yml          # Container build + deploy
    └── security-scans.yml      # Trivy vulnerability scanning
```
