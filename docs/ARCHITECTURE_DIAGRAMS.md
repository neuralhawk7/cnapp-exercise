# Architecture Diagrams

This document contains architecture diagrams for the Wiz Technical Exercise.

## System Overview

The system consists of:
- **Frontend**: Kubernetes-deployed Express application
- **Backend**: MongoDB on EC2
- **Infrastructure**: AWS (VPC, EKS, EC2, S3)
- **Security**: GuardDuty, Security Hub, Inspector, WAF, CloudTrail
- **CI/CD**: GitHub Actions with Terraform and container workflows

See EXERCISE_GUIDE.md for detailed Mermaid diagrams.
