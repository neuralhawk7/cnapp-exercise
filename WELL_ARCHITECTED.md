# AWS Well-Architected Alignment

This document maps this repo's implementation to the AWS Well-Architected Framework pillars. It is intended as evidence of review and coverage for the assignment.

## Operational Excellence
- Infrastructure as Code: Terraform in terraform/ with versioned changes and reviews.
- Automated checks: GitHub Actions workflows for Terraform validate and Checkov scans.
- Observability: CloudTrail, AWS Config, GuardDuty, Security Hub findings to SNS.
- Runbooks: Deployment steps documented in DEPLOYMENT_README.md.

## Security
- Threat detection: GuardDuty and Detective enabled.
- Security posture: Security Hub (AWS Foundational + CIS) with product subscriptions.
- Vulnerability management: Inspector2 enabled for EC2 and ECR.
- Network protection: WAF on ALB with managed rules in count mode and rate-based rules.
- Logging: CloudTrail multi-region, AWS Config recorder, VPC flow logs.
- Access: IAM role for EC2, optional SSM access for management.

## Reliability
- VPC with public and private subnets and managed EKS for app workloads.
- Infrastructure defined declaratively to support repeatable provisioning.
- Health checks and load balancer in place for the WAF test ALB.

## Performance Efficiency
- Managed services (EKS, ALB, WAF) to reduce operational overhead.
- EKS autoscaling parameters set in Terraform (min/desired/max).

## Cost Optimization
- Right-sized defaults for EC2 and EKS nodes (t3 instances).
- Centralized logging to S3 with retention policy on VPC flow logs.

## Sustainability
- Managed services reduce operational overhead and maintenance.
- Right-sized compute defaults minimize idle capacity.

## Evidence and Artifacts
- Terraform configuration: terraform/main.tf, terraform/variables.tf.
- Workflows: .github/workflows/infra-ci.yml and security scans.
- Deployment summary: DEPLOYMENT_README.md.
