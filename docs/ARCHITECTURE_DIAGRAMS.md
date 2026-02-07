# Architecture Diagrams

This document contains architecture diagrams for an intentionally vulnerable Web App on EKS with a Debian 10 (Buster) MongoDB 4.2 backend. 

## System Overview

The system consists of:
- **Frontend**: Kubernetes-deployed Express application
- **Backend**: MongoDB on EC2
- **Infrastructure**: AWS (VPC, EKS, EC2, S3)
- **Security**: GuardDuty, Security Hub, Inspector, WAF, CloudTrail
- **CI/CD**: GitHub Actions with Terraform and container workflows

See EXERCISE_GUIDE.md for detailed diagrams.
