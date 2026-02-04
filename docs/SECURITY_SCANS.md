# Security scans (Trivy & Legitify) 🔒

This repository includes non-blocking security scans that run on PRs and pushes. The scans surface findings as SARIF artifacts and upload them to GitHub Code Scanning (optional). All jobs are intentionally non-blocking so they provide visibility without failing CI.

## What runs

- Trivy — filesystem and IaC scans by default. If a `Dockerfile` is present in `app/` (or repo root), the workflow will attempt to build the image locally and run a Trivy image scan (SARIF). The built image uses the tag `${{ github.repository }}:${{ github.sha }}`.
- **Legitify** — GitHub repo/workflow and settings checks. For org-level checks you may need a PAT with extra scopes.

## Where the workflow lives

- `.github/workflows/security-scans.yml`

## Secrets & tokens

- **LEGITIFY_TOKEN** (optional): Store a GitHub Personal Access Token (recommend: Fine-grained PAT) as a repository secret named `LEGITIFY_TOKEN` when you need Legitify to scan with extra permissions.
  - To create a Fine-grained PAT: GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token. Grant only the minimum required repo/org permissions and set an expiration.
  - Add the PAT in the repo: Settings → Secrets and variables → Actions → New repository secret → `LEGITIFY_TOKEN`.

- **GHCR_PAT** (optional): Personal Access Token with `packages:write` (or allow the `GITHUB_TOKEN` to have `packages: write` permissions for the workflow) to push images to GitHub Container Registry (GHCR). Store as `GHCR_PAT` in repository secrets to enable GHCR pushes.

- **AWS / ECR secrets** (optional): To push images to Amazon ECR, add the following repository secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION`
  - `ECR_REGISTRY` (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com`)
  - `ECR_REPOSITORY` (e.g., `cnapp-exercise`)

**Security note:** You posted a PAT in chat earlier — please revoke that token immediately and create a new one; never paste tokens into chat or commit them to source control.

**Behavior note:** The workflow will attempt GHCR and ECR pushes only when a `Dockerfile` is present. If required secrets are missing the push steps will be skipped (non-blocking). This provides mirrored images in GHCR and ECR when you add secrets and enables both GitHub-native scans/Dependabot and AWS-native scans in ECR.

## Run locally

- Trivy IaC: `trivy iac . --format sarif --output trivy-iac.sarif`
- Trivy filesystem: `trivy fs . --format sarif --output trivy-fs.sarif`
- Legitify (if installed): `legitify scan --github-token $LEGITIFY_TOKEN --format sarif --output legitify.sarif`

## Behavior & intent

- All workflows are informational and non-blocking. They upload SARIF and artifacts for visibility in the GitHub UI and as downloadable artifacts on the run.
- If you want the scans to fail CI for certain severities, we can add gating (fail-on-severity) or make specific jobs fail on non-zero exit codes.
