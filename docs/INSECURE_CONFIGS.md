# Intentionally Insecure Configurations 🔍

This file documents **the intentionally insecure choices** in this repository used for CNAPP/CSPM testing, why they trigger security alerts, and suggested remediation guidance.

## Summary of intentionally insecure items

- **Public S3 bucket with listing and public-read objects**
  - Where: `terraform/main.tf` and `terraform/mongo-vm/*`
  - Why it's insecure: Public buckets allow anyone on the internet to list and download objects. Backups containing sensitive data (e.g., DB dumps) should never be publicly accessible.
  - CNAPP signals: public S3 policies/ACLs, high severity exposure of data.
  - Suggested fix: remove public policy, deny public ACLs, require encryption and least privileged IAM.

- **EC2 instance with AdministratorAccess instance profile**
  - Where: `terraform/main.tf` and `terraform/mongo-vm/main.tf`
  - Why it's insecure: An instance with wide permissions can be used as a pivot to escalate access and modify resources across the account.
  - CNAPP signals: excessive IAM roles, resource with broad permissions.
  - Suggested fix: follow least privilege — narrow IAM policies to only required actions.

- **Security Group allowing SSH from 0.0.0.0/0**
  - Where: `terraform/main.tf`
  - Why it's insecure: Wide-open SSH exposes the VM to brute-force or automated attacks.
  - CNAPP signals: open ingress rules for management ports.
  - Suggested fix: restrict SSH to trusted IP ranges (e.g., `var.my_ip_cidr`) or use a bastion with limited access.

- **Outdated OS & Database versions (Debian 10, MongoDB 4.2)**
  - Where: `terraform/mongo-vm/userdata.sh.tftpl`
  - Why it's insecure: Older OS/DB versions may contain unpatched vulnerabilities.
  - CNAPP signals: known vulnerable package versions.
  - Suggested fix: upgrade to supported OS and DB releases and apply regular patching.

- **Backup script uploads using `--acl public-read`**
  - Where: `terraform/mongo-vm/userdata.sh.tftpl` (backup cron)
  - Why it's insecure: Cloud backups should not be publicly readable.
  - CNAPP signals: object ACLs granting public read access.
  - Suggested fix: remove `--acl public-read` and rely on bucket policies + encryption + access logging.

## Why these are present

This repository is explicitly intended as a testbed for CNAPP and security tooling: the insecure choices are educational and used to verify detection/alerting behavior. If you want to harden the repo for production, follow the remediation guidance above.

---

For more details on the Checkov setup and how scans run on PRs, see `docs/CHECKOV.md`.
