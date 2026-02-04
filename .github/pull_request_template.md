## PR checklist ✅

- [ ] Add or confirm required repository secrets for registry pushes if you want images pushed automatically:
  - `GHCR_PAT` (optional) — PAT with `packages:write` to push to GHCR. If not provided, the workflow will try `GITHUB_TOKEN` which may lack permissions to push packages.
  - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `ECR_REGISTRY`, `ECR_REPOSITORY` (optional) — required for ECR pushes. The workflow will attempt to create the ECR repository if it doesn't exist.
- [ ] Check that the `Dockerfile` (if present) builds locally and that the image is what you expect.
- [ ] If you previously leaked any tokens into the PR, revoke/rotate them and confirm rotation in the PR comments.
- [ ] Keep scans non-blocking for now; review Trivy/Checkov/Legitify artifacts in the workflow run and triage findings.

Notes
- The workflow will push three tags for images when pushing to registries: `sha` (full commit), `sha-short` (7 chars), and `latest` (non-blocking). This mirrors images to GHCR and ECR so you can use both GitHub-native scans and AWS ECR scans.
- If you want pushes to be disabled entirely, do not add the registry secrets.
