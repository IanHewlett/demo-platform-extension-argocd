#!/usr/bin/env bash
set -eo pipefail


while [[ $(kubectl get applications -A -o json | jq -r '[.items[] | select(.status.health.status != "Healthy").metadata.name] | length') != 0 ]]; do
  echo -e
  echo "not healthy applications:"
  kubectl get applications -A -o json | jq -r '[.items[] | select(.status.health.status != "Healthy").metadata.name]' --compact-output

  echo "healthy applications:"
  kubectl get applications -A -o json | jq -r '[.items[] | select(.status.health.status == "Healthy").metadata.name]' --compact-output

  echo "waiting for 5 seconds..."
  sleep 5;
  echo -e
done

echo -e
echo -e "all applications healthy:\n"
kubectl get Application -A && echo -e
kubectl get ApplicationSet -A && echo -e
kubectl get AppProject -A && echo -e
echo -e

while [[ $(kubectl get applications -A -o json | jq -r '[.items[] | select(.status.sync.status != "Synced").metadata.name] | length') != 0 ]]; do
  echo -e
  echo "not synced applications:"
  kubectl get applications -A -o json | jq -r '[.items[] | select(.status.sync.status != "Synced").metadata.name]' --compact-output

  echo "synced applications:"
  kubectl get applications -A -o json | jq -r '[.items[] | select(.status.sync.status == "Synced").metadata.name]' --compact-output

  echo "waiting for 5 seconds..."
  sleep 5;
  echo -e
done

echo -e
echo -e "all applications synced:\n"
kubectl get Application -A && echo -e
kubectl get ApplicationSet -A && echo -e
kubectl get AppProject -A && echo -e
echo -e
