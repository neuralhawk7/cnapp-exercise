# Deployment and Architecture Overview

This document describes the deployment flow, architecture, and the detective and preventive controls implemented for the assignment.

## Architecture Summary
- VPC with public and private subnets.
- EKS cluster for application workloads.
- EC2 MongoDB instance in public subnet with restricted MongoDB access to VPC CIDR.
- Application Load Balancer used for WAF testing.
- S3 bucket for MongoDB backups (intentionally public to support the exercise).

## Deployment Flow
1) Initialize and apply Terraform:
- terraform -chdir=terraform init
- terraform -chdir=terraform plan
- terraform -chdir=terraform apply

2) Import detective controls if already enabled in the account:
- bash terraform/import-detective-controls.sh

3) Build and deploy the app image and workload (if needed):
- Build and push container to ECR.
- Deploy Kubernetes manifests under app/.

## Detective Controls Implemented
- GuardDuty enabled via Terraform.
- Detective enabled via Terraform.
- Security Hub enabled with AWS Foundational and CIS standards.
- Security Hub subscriptions for GuardDuty, Inspector, and AWS Config.
- CloudTrail multi-region trail with log file validation.
- AWS Config recorder and delivery channel.
- Inspector2 enabled for EC2 and ECR.
- VPC Flow Logs to CloudWatch Logs.
- WAF logging and metrics with managed rule sets in count mode.
- Security Hub findings routed to an SNS topic for notifications.

## Preventive Controls Implemented
- WAF managed rule sets (count mode to start) and rate-based rule.
- Security groups restrict MongoDB access to the VPC CIDR.
- IAM roles and instance profiles are defined for workload access.

## Preventive Controls Recommended (Guidance)
- SCPs in AWS Organizations to deny disabling GuardDuty and restrict regions.
- S3 Block Public Access at the account level (except for exercise-specific buckets).
- IAM permission boundaries and least privilege.
- KMS encryption by default for EBS, S3, and ECR.
- ECR lifecycle policies and scanning on push.

## Immutability and Change Control
- Infrastructure is managed via Terraform and versioned in Git.
- Container images are built and pushed to ECR, and Kubernetes manifests reference immutable image tags when used.
- Changes are made via pull requests and CI checks.

## SSM and Instance Management
- The EC2 role includes AmazonSSMManagedInstanceCore for Systems Manager access.
- Install the SSM Agent on Debian 10 using the official AWS package:
  - curl -fsSL -o /tmp/amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
  - sudo dpkg -i /tmp/amazon-ssm-agent.deb
  - sudo systemctl enable --now amazon-ssm-agent

## Notes
- Some resources are intentionally insecure for CNAPP testing.
- Use the provided Terraform variables to tailor the deployment.
