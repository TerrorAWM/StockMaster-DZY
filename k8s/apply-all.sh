#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f namespace.yaml
kubectl apply -f mysql/mysql.yaml
kubectl apply -f services/base-config.yaml
kubectl apply -f services/apps.yaml

