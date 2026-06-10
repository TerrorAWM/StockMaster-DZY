#!/usr/bin/env bash
set -euo pipefail

: "${GHCR_USERNAME:?Set GHCR_USERNAME first.}"
: "${GHCR_TOKEN:?Set GHCR_TOKEN to a token with read:packages permission.}"

kubectl create namespace stockmaster --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry ghcr-pull \
  --namespace stockmaster \
  --docker-server=ghcr.io \
  --docker-username="${GHCR_USERNAME}" \
  --docker-password="${GHCR_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl patch serviceaccount default \
  --namespace stockmaster \
  --type merge \
  --patch '{"imagePullSecrets":[{"name":"ghcr-pull"}]}'

echo "GHCR pull secret configured for the stockmaster namespace."
