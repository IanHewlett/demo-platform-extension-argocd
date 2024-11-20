#!/usr/bin/env bash
set -eo pipefail


kubectl apply -f environments/demo/mesh/argocd/argocd-ns.yaml

kubectl create secret generic argocd-sync-secret -n argocd \
  --from-literal=git_username=username \
  --from-literal=git_token="$GH_PAT" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -k environments/demo/mesh/argocd

kubectl apply -k environments/demo/clusters/demo-minikube-us-east-0
