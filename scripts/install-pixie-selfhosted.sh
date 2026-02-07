#!/usr/bin/env bash
set -euo pipefail

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required." >&2
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required." >&2
  exit 1
fi

: "${PX_CLOUD_ADDR:?Set PX_CLOUD_ADDR to your Pixie Cloud address}"
: "${PX_DEPLOY_KEY:?Set PX_DEPLOY_KEY to your Pixie deploy key}"

helm repo add pixie https://pixie-operator-charts.storage.googleapis.com
helm repo update

helm upgrade --install pixie pixie/pixie-operator-chart \
  --namespace pl \
  --create-namespace \
  --set cloudAddr="${PX_CLOUD_ADDR}" \
  --set deployKey="${PX_DEPLOY_KEY}"

echo "Pixie operator installed in namespace 'pl'."
