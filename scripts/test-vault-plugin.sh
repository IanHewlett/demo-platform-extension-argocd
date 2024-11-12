#!/usr/bin/env bash
set -eo pipefail


echo "apply test application manifest"
kubectl apply -f test/e2e/argocd-vault-plugin/sample-secret.yaml

echo "wait for test application to be healthy"
while [[ $(kubectl get application -n argocd sample-secret -o 'jsonpath={.status.health}' | jq -r '.status') != "Healthy" ]]; \
  do echo "not ready" && sleep 1; done

echo "check if rendered secret matches vault value"
if [[ "$(kubectl get secret -n argocd example-secret -o jsonpath='{.data.sample-secret}' | base64 --decode)" == "secret" ]]; then
  echo "they match"
else
  echo "they do not match"
fi
