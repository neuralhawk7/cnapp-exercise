# Learn Terraform - Provision an EKS Cluster

This repo is a companion repo to the [Provision an EKS Cluster tutorial](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks), containing
Terraform configuration files to provision an EKS cluster on AWS.

## Security note ⚠️
This Terraform configuration intentionally includes insecure choices for CNAPP testing (public S3, open SSH, overly permissive instance roles, etc.). See `../docs/INSECURE_CONFIGS.md` for details and `../docs/CHECKOV.md` for information on the non-blocking Checkov scan that runs on PRs.
