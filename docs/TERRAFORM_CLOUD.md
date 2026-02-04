Terraform Cloud (TFC) Setup — cnapp-exercise

Overview

This document explains how to connect this repository to Terraform Cloud and how the GitHub Action will trigger plan runs in TFC.

Prerequisites
- A Terraform Cloud account and organization (you said this is already configured).
- A workspace in TFC named `cnapp-exercise` (you can choose a different name but update the backend/workflow variables accordingly).
- A Terraform Cloud API token (create in User Settings → Tokens).

Files added
- `terraform/backend.tf`
  - Configures Terraform to use TFC as the remote backend. Replace `YOUR_ORG` with your organization name.

Workspace configuration
1. Create a new workspace in Terraform Cloud (or use an existing one):
   - Organization: your org
   - Workspace name: `cnapp-exercise` (or change backend.tf/workflow env accordingly)
   - Connect the workspace to this GitHub repository (VCS) for automatic runs, or leave disconnected and use the GitHub workflow to trigger runs.
2. In Workspace → Variables, add the following environment variables (sensitive where indicated):
   - `AWS_ACCESS_KEY_ID` (sensitive) — *or* configure an IAM role for TFC
   - `AWS_SECRET_ACCESS_KEY` (sensitive)
   - `AWS_REGION` (not sensitive)
   - Any Terraform variables you need, e.g. `mongo_admin_pass` (sensitive)

GitHub secrets (for the trigger workflow)
- Set the repository secret `TFC_TOKEN` to a Terraform Cloud token (sensitive)
- Optionally set `TFC_ORG` and `TFC_WORKSPACE` repository secrets, or set them as inputs when dispatching the workflow

Triggering a plan from GitHub
- A new workflow `.github/workflows/tfc-trigger-plan.yml` is included. It will:
  - Run on `pull_request` and `workflow_dispatch`
  - Use your `TFC_TOKEN` and organization/workspace variables to create a run in Terraform Cloud via the TFC API
  - The workspace will execute the plan (TFC UI shows the plan). Approve the run in the TFC UI to apply (unless workspace is set to auto-apply).

Notes & best practices
- Prefer Manual Apply in Terraform Cloud for safety during initial setup.
- Use Terraform Cloud variables for secrets; do not commit `terraform.tfvars` with secrets.
- Consider enabling workspace protection and using Sentinel or policy checks for production workflows.

If you want, I can also create a small `workflow_dispatch` apply trigger that will call the TFC API to mark a run as "apply" once the plan is ready, but manual approval in the TFC UI is recommended for safety.
