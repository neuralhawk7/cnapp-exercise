# GitHub Copilot instructions for cnapp-exercise 🚀

## Quick summary
- Purpose: intentionally misconfigured Terraform project used for CNAPP (cloud native application) testing. Main focus is AWS resources: an EKS companion configuration and a standalone Mongo VM used to demonstrate insecure patterns.
- Key areas: Terraform configs in `/terraform`, a dedicated `mongo-vm` Terraform module, and the VM provisioning script at `terraform/mongo-vm/userdata.sh.tftpl`.

---

## What to know (big picture) 🔧
- Infrastructure-as-code: The codebase is Terraform-first. Top-level Terraform files live in `/terraform` and include a small example `terraform.tfvars.example`. A separate `terraform/mongo-vm` folder contains an alternate (module-like) implementation of the Mongo VM.
- Components & boundaries:
  - Terraform (root): `terraform/main.tf` provisions VPC resources (IGW, subnet, route-table), a public S3 bucket, a high-privilege IAM role/profile, and an EC2 instance for Mongo. It demonstrates *global* insecure defaults (e.g., SSH from 0.0.0.0/0).
  - `terraform/mongo-vm/`: similar behavior but expects an *existing* VPC (data sources). It uses `userdata.sh`/`userdata.sh.tftpl` to bootstrap Mongo and daily backups.
  - Runtime behavior: the VM runs Debian 10 + MongoDB 4.2, creates an admin user, enables auth, and runs a daily mongodump uploaded to an S3 bucket (public-read + listing). The VM also has an instance profile with AdministratorAccess.

## Project-specific patterns & gotchas ⚠️
- Intentionally insecure choices to watch for (these are expected in this exercise):
  - Public S3 bucket with a policy that allows List + Get (see `terraform/main.tf` S3 resources and `terraform/mongo-vm` S3 config).
  - EC2 instance with an attached IAM instance profile that has `AdministratorAccess` (see `aws_iam_role_policy_attachment` in both `main.tf` files).
  - Outdated OS & DB: Debian 10 and MongoDB 4.2 installed in `terraform/mongo-vm/userdata.sh.tftpl`.
  - Backup script uploads with `--acl public-read` (see `mongo_backup.sh` inside the userdata template).
  - Top-level `aws_security_group.mongo_vm` in `terraform/main.tf` allows SSH from `0.0.0.0/0` (exercise-specific misconfiguration).
- Implementation pattern: Terraform uses `templatefile()` to inject secrets/vars into the instance `user_data`. Credentials like `mongo_admin_pass` are declared as sensitive variables (see `variables.tf`).

## How to run & reproduce (developer workflows) ▶️
- Terraform CLI (recommended):
  - Copy `terraform/terraform.tfvars.example` → `terraform/terraform.tfvars` and fill required values (do not commit `terraform.tfvars`, already in `.gitignore`).
  - From `/terraform`:
    - `terraform init`
    - `terraform plan` (review plan carefully — the intent is to identify insecure resources)
    - `terraform apply` to create resources (be mindful of AWS costs & deliberate insecure infra)
  - Cleanup: `terraform destroy` when done.
- Tooling versions: module `terraform/mongo-vm/main.tf` expects Terraform >= 1.6.0; top-level uses `~> 1.3`. Prefer using Terraform >= 1.6 for consistent behavior.
- No CI tests present: there are no GitHub Actions or unit/integration tests currently. PR reviewers should expect manual verification steps.

## Where to look for examples (quick links) 🔎
- `terraform/main.tf` — top-level provisioning (public SSH, S3 public listing, admin role).
- `terraform/mongo-vm/userdata.sh.tftpl` — VM bootstrap, Mongo install, daily backup script, cron configuration.
- `terraform/mongo-vm/variables.tf` — variable names like `my_ip_cidr`, `mongo_admin_pass` and defaults.
- `terraform/terraform.tfvars.example` — sample values for quick redeploys.

## Guidance for AI agents (focus & actions) 🤖
- Priorities when editing or reviewing code:
  1. Preserve the exercise intent: these insecure settings are deliberate. When asked to "fix" security issues, explicitly confirm whether to preserve the exercise intent or to harden for production.
  2. When changing infra, update examples (`terraform.tfvars.example`) and add a succinct note in `README.md` explaining the reason for changes.
  3. Make minimal, testable changes (e.g., tighten a security group CIDR using `var.my_ip_cidr` and add comments pointing to the exercise purpose).
- When adding tests or CI: add simple terraform plan checks (e.g., `terraform validate`, `terraform fmt -check`, and `terraform plan -out=plan.tfplan && terraform show -json plan.tfplan | jq '.'`) and a short GitHub Action under `.github/workflows` only if asked.

## Safety & communication 📣
- If the user asks to remove insecure configurations, confirm whether they want to maintain the repo's educational/misaligned purpose before making changes.
- For any change that removes intentionally vulnerable resources, add a small note in `README.md` and keep the original implementation in a branch or as a commented example.

---

If you'd like, I can open a draft PR adding this file, or iterate on the wording to include any specific checks or task templates you want automated. Do you want edits that harden the infrastructure or keep the exercise as-is? ✅