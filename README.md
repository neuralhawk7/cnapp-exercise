# cnapp-exercise
An intentionally misconfigured project for CNAPP testing

## Security note ✅
This repository intentionally contains insecure Terraform configurations used for CNAPP/CSPM testing. A non-blocking Checkov scan runs on push and pull requests to surface misconfigurations (it will not fail CI). See `docs/INSECURE_CONFIGS.md` for a list of intentionally insecure resources and why they trigger CNAPP alerts, and `docs/CHECKOV.md` for details about the Checkov scan and how to run it locally.
