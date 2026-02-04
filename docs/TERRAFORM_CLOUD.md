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

Bootstrapping a workspace from GitHub ✅
- A new workflow `.github/workflows/tfc-bootstrap.yml` is included to help bootstrap a TFC workspace and set workspace variables from repository secrets. Use it when you want the repository to create the workspace (if missing) and populate variables automatically.

Required repository secrets (set in GitHub repo Settings → Secrets):
- `TFC_TOKEN` (Terraform Cloud API token) — **required** and **sensitive**
- `TFC_ORG` — default organization name (optional if you pass via workflow inputs)
- `TFC_WORKSPACE` — default workspace name (optional if you pass via workflow inputs)
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` — **sensitive** (or configure a role/credentials in TFC)
- `AWS_REGION` — region, e.g. `us-east-1`
- `MONGO_ADMIN_PASS` — **sensitive** (optional; will be added as a Terraform variable)
- `SSH_PUBLIC_KEY` — **sensitive** (optional; helps bootstrap SSH upload or future tf vars)

How to run the bootstrap workflow
1. Set the repository secrets listed above (at minimum `TFC_TOKEN`, `TFC_ORG`, `TFC_WORKSPACE`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`).
2. In the GitHub UI go to the Actions tab → choose "Terraform Cloud — bootstrap workspace" and click "Run workflow". You can also pass `org` and `workspace` as inputs.
3. The workflow will create the workspace (if missing) and add the variables using the values from the repository secrets. It does **not** automatically connect VCS; after the workspace exists, connect it to the GitHub repo in the TFC UI for automatic runs.

Notes & best practices
- Prefer Manual Apply in Terraform Cloud for safety during initial setup.
- Use Terraform Cloud workspace variables for secrets; do not commit `terraform.tfvars` with secrets.
- Consider enabling workspace protection and using Sentinel or policy checks for production workflows.

If you want, I can also create a small `workflow_dispatch` apply trigger that will call the TFC API to mark a run as "apply" once the plan is ready, but manual approval in the TFC UI is recommended for safety.
