# Checkov scanning (non-blocking) ✅

This repository includes a GitHub Action that runs Checkov against the Terraform code to surface IaC misconfigurations during PRs and pushes.

## Key points

- The workflow is defined at `.github/workflows/checkov.yml` and runs on `pull_request` and `push` events.
- The scan is **informational** and **non-blocking**: Checkov is executed but it is configured so that the CI job will not fail the PR if issues are found.
- Results are produced in SARIF format and uploaded as an artifact named `checkov-sarif`. The workflow also uploads SARIF to GitHub Code Scanning so findings can appear as code scanning alerts and annotations.

## Run locally

1. Install Checkov: `pip install checkov`
2. Run against the `terraform` directory:

   checkov -d terraform --output-file checkov.sarif --output-format sarif

3. You can inspect the SARIF file or upload it to code scanning if needed.

## What Checkov typically flags here

- Public S3 buckets or policies granting public list/get
- Wide open security groups (e.g., SSH from 0.0.0.0/0)
- Overly permissive IAM roles and instance profiles
- Use of public ACLs on objects

If you'd like the action to become blocking in the future (fail PRs when critical issues are discovered), we can change the workflow to fail on non-zero exit code or add gating logic based on severity.

---

Note: This repo also runs non-blocking Trivy and Legitify scans (see `docs/SECURITY_SCANS.md`) which scan for container/image vulnerabilities, IaC issues, and GitHub/workflow misconfigurations.