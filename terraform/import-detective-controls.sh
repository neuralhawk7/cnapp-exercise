#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AWS_REGION_VALUE="${AWS_REGION:-$(aws configure get region || true)}"
if [[ -z "${AWS_REGION_VALUE}" ]]; then
  echo "AWS region not set. Export AWS_REGION or configure a default region." >&2
  exit 1
fi

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

GUARDDUTY_DETECTOR_ID="$(aws guardduty list-detectors --region "${AWS_REGION_VALUE}" --query 'DetectorIds[0]' --output text || true)"
DETECTIVE_GRAPH_ARN="$(aws detective list-graphs --region "${AWS_REGION_VALUE}" --query 'GraphList[0].Arn' --output text || true)"

if [[ -n "${GUARDDUTY_DETECTOR_ID}" && "${GUARDDUTY_DETECTOR_ID}" != "None" ]]; then
  terraform -chdir="${ROOT_DIR}" import 'aws_guardduty_detector.main[0]' "${GUARDDUTY_DETECTOR_ID}"
else
  echo "GuardDuty detector not found; skipping import."
fi

if [[ -n "${DETECTIVE_GRAPH_ARN}" && "${DETECTIVE_GRAPH_ARN}" != "None" ]]; then
  terraform -chdir="${ROOT_DIR}" import 'aws_detective_graph.main[0]' "${DETECTIVE_GRAPH_ARN}"
else
  echo "Detective graph not found; skipping import."
fi

if [[ -n "${ACCOUNT_ID}" && "${ACCOUNT_ID}" != "None" ]]; then
  terraform -chdir="${ROOT_DIR}" import 'aws_securityhub_account.main[0]' "${ACCOUNT_ID}"
else
  echo "Account ID not found; skipping Security Hub import."
fi
